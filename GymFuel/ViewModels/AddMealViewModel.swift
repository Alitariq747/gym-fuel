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
    @Published var descriptionText: String = ""
    @Published var selectedPhotoData: Data? = nil
    @Published var selectedPhotoMimeType: String = "image/jpeg"
    @Published var selectedPhotoFilename: String = "meal.jpg"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var parsed: ParsedMeal? = nil
    @Published var isPreparingImage: Bool = false

    var isPhotoReady: Bool {
        selectedPhotoData != nil && !isPreparingImage && errorMessage == nil
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
            errorMessage = error.localizedDescription
        }
    }

    func reset() {
        descriptionText = ""
        selectedPhotoData = nil
        selectedPhotoMimeType = "image/jpeg"
        selectedPhotoFilename = "meal.jpg"
        parsed = nil
        errorMessage = nil
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
                    self.errorMessage = error.localizedDescription
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
    }
}
