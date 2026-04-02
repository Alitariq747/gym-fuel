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
    enum RecoveryAction {
        case retry
        case chooseNewPhoto
        case dismiss
        case manualFallback
        case signIn
    }

    enum UserFacingError: String {
        case offline = "You're offline. Check your connection and try again."
        case timeout = "This is taking too long. Please try again."
        case server = "We’re having trouble on our end. Please try again later."
        case invalidResponse = "We couldn’t understand the response. Please try again."
        case imageTooLarge = "This image is too large to upload. Try a different photo."
        case signInRequired = "Please sign in to continue."
        case sessionExpired = "Your session expired. Please sign in again."
        case accountDisabled = "This account has been disabled."
        case textQuotaExceeded = "You have reached your monthly text scan limit."
        case imageQuotaExceeded = "You have reached your monthly image scan limit."
        case textRateLimited = "Too many text meal requests. Please wait a moment and try again."
        case imageRateLimited = "Too many image meal requests. Please wait a moment and try again."
        case unknown = "Something went wrong. Please try again."

        var recoveryAction: RecoveryAction {
            switch self {
            case .offline, .timeout, .server:
                return .retry
            case .imageTooLarge:
                return .chooseNewPhoto
            case .signInRequired, .sessionExpired:
                return .signIn
            case .textQuotaExceeded, .imageQuotaExceeded, .textRateLimited, .imageRateLimited:
                return .manualFallback
            case .invalidResponse, .accountDisabled, .unknown:
                return .dismiss
            }
        }
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
    private var activePhotoRequestId = UUID()
    private var activeParseRequestId = UUID()

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

    var currentRecoveryAction: RecoveryAction? {
        lastUserFacingError?.recoveryAction
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
        let requestId = UUID()
        activeParseRequestId = requestId
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
            guard activeParseRequestId == requestId else { return }
            parsed = result
        } catch {
            guard activeParseRequestId == requestId else { return }
            let friendlyError = mapToUserFacingError(error)
            lastUserFacingError = friendlyError
            errorMessage = friendlyError.rawValue
        }
    }

    func reset() {
        descriptionText = ""
        clearImageFlowState()
    }

    func setSelectedPhoto(_ image: UIImage) {
        errorMessage = nil
        parsed = nil

        isPreparingImage = true
        let requestId = UUID()
        activePhotoRequestId = requestId
        Task.detached(priority: .userInitiated) { [imagePreprocessor] in
            do {
                let processed = try imagePreprocessor.preprocess(image)
                await MainActor.run {
                    guard self.activePhotoRequestId == requestId else { return }
                    self.selectedPhotoData = processed.data
                    self.selectedPhotoMimeType = processed.mimeType
                    self.selectedPhotoFilename = processed.filename
                    self.isPreparingImage = false
                }
            } catch {
                await MainActor.run {
                    guard self.activePhotoRequestId == requestId else { return }
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

    func clearImageFlowState() {
        activePhotoRequestId = UUID()
        activeParseRequestId = UUID()
        selectedPhotoData = nil
        selectedPhotoMimeType = "image/jpeg"
        selectedPhotoFilename = "meal.jpg"
        parsed = nil
        errorMessage = nil
        isLoading = false
        isPreparingImage = false
        lastUserFacingError = nil
    }

    func removeSelectedPhoto() {
        clearImageFlowState()
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
            case .unauthenticated, .unauthorized:
                return .signInRequired
            case .sessionExpired:
                return .sessionExpired
            case .accountDisabled:
                return .accountDisabled
            case .textQuotaExceeded:
                return .textQuotaExceeded
            case .imageQuotaExceeded:
                return .imageQuotaExceeded
            case .aiTimeout:
                return .timeout
            case .textRateLimited:
                return .textRateLimited
            case .imageRateLimited:
                return .imageRateLimited


            }
        }
        return .unknown
    }
}
