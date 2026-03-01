//
//  AddMealViewModel.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/12/2025.
//

import Foundation
import SwiftUI
import UIKit

@MainActor
final class AddMealViewModel: ObservableObject {
    enum UserFacingError: String {
        case offline = "You're offline. Check your connection and try again."
        case timeout = "This is taking too long. Please try again."
        case server = "We’re having trouble on our end. Please try again later."
        case invalidResponse = "We couldn’t understand the response. Please try again."
        case imageTooLarge = "This image is too large to upload. Try a different photo."
        case unknown = "Something went wrong. Please try again."
    }

    @Published var descriptionText: String = ""
    @Published var selectedPhotoData: Data? = nil
    @Published var selectedPhotoMimeType: String = "image/jpeg"
    @Published var selectedPhotoFilename: String = "meal.jpg"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var parsed: ParsedMeal? = nil
    @Published var isPreparingImage: Bool = false
    @Published private(set) var lastUserFacingError: UserFacingError? = nil

    var isPhotoReady: Bool {
        selectedPhotoData != nil && !isPreparingImage && errorMessage == nil
    }

    var canRetry: Bool {
        switch lastUserFacingError {
        case .offline, .timeout, .server:
            return true
        default:
            return false
        }
    }

    private let service: MealParsingService
    private let imagePreprocessor: MealImagePreprocessing

    init(
        service: MealParsingService,
        imagePreprocessor: MealImagePreprocessing = MealImagePreprocessor()
    ) {
        self.service = service
        self.imagePreprocessor = imagePreprocessor
    }

    func parse() async {
        errorMessage = nil
        parsed = nil
        lastUserFacingError = nil

        let input = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasPhoto = selectedPhotoData != nil
        guard !input.isEmpty || hasPhoto else {
            errorMessage = "Please add a photo or describe your meal."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let request: MealParseInput
            if let photoData = selectedPhotoData {
                request = .photo(
                    data: photoData,
                    mimeType: selectedPhotoMimeType,
                    filename: selectedPhotoFilename
                )
            } else {
                request = .text(description: input)
            }

            let result = try await service.parseMeal(request)
            parsed = result
        } catch {
            let friendlyError = mapToUserFacingError(error)
            lastUserFacingError = friendlyError
            errorMessage = friendlyError.rawValue
        }
    }

    func reset() {
        descriptionText = ""
        selectedPhotoData = nil
        selectedPhotoMimeType = "image/jpeg"
        selectedPhotoFilename = "meal.jpg"
        parsed = nil
        errorMessage = nil
        lastUserFacingError = nil
        isLoading = false
    }

    func setSelectedPhoto(_ image: UIImage) {
        errorMessage = nil
        parsed = nil

        isPreparingImage = true
        Task.detached(priority: .userInitiated) { [imagePreprocessor] in
            do {
                let processed = try imagePreprocessor.preprocess(image)
                await MainActor.run {
                    self.selectedPhotoData = processed.data
                    self.selectedPhotoMimeType = processed.mimeType
                    self.selectedPhotoFilename = processed.filename
                    self.isPreparingImage = false
                }
            } catch {
                await MainActor.run {
                    self.selectedPhotoData = nil
                    self.selectedPhotoMimeType = "image/jpeg"
                    self.selectedPhotoFilename = "meal.jpg"
                    let friendlyError = self.mapToUserFacingError(error)
                    self.lastUserFacingError = friendlyError
                    self.errorMessage = friendlyError.rawValue
                    self.isPreparingImage = false
                }
            }
        }
    }

    func removeSelectedPhoto() {
        selectedPhotoData = nil
        selectedPhotoMimeType = "image/jpeg"
        selectedPhotoFilename = "meal.jpg"
        isPreparingImage = false
        lastUserFacingError = nil
    }

    private func mapToUserFacingError(_ error: Error) -> UserFacingError {
        if let preprocessorError = error as? MealImagePreprocessorError {
            switch preprocessorError {
            case .imageTooLargeAfterCompression:
                return .imageTooLarge
            case .encodingFailed:
                return .unknown
            }
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .offline
            case .timedOut:
                return .timeout
            default:
                return .unknown
            }
        }

        if let backendError = error as? BackendMealParsingService.ServiceError {
            switch backendError {
            case .httpError:
                return .server
            case .decodingFailed:
                return .invalidResponse
            case .invalidURL:
                return .unknown
            }
        }

        return .unknown
    }
}
