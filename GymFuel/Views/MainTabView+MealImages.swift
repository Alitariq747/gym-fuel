import Foundation
import PhotosUI
import UIKit

extension MainTabView {
    func loadSelectedPhotoData() async {
        guard let selectedPhotoPickerItem else { return }

        do {
            let imageData = try await selectedPhotoPickerItem.loadTransferable(type: Data.self)
            guard let imageData else {
                mealImageDraft.state = .failed("We couldn't load that photo. Please try another image.")
                return
            }

            let preparedImage = try await prepareMealImageDataOffMain(imageData)
            mealImageDraft.originalData = preparedImage.originalData
            mealImageDraft.compressedJPEGData = preparedImage.compressedJPEGData
            mealImageDraft.state = .readyToAnalyze
        } catch {
            mealImageDraft.state = .failed(AppErrorMessage.message(
                for: error,
                fallback: "We couldn't prepare that photo. Please try a different image."
            ))
        }
    }

    func handleCapturedMealImage(_ image: UIImage) {
        dismissComposerKeyboard()
        showCameraCapture = false
        pendingMealImageSource = nil

        mealImageDraft.source = .camera
        mealImageDraft.state = .preparing
        Task {
            await prepareCapturedMealImage(image)
        }
    }

    func prepareCapturedMealImage(_ image: UIImage) async {
        do {
            let preparedImage = try await Task.detached(priority: .userInitiated) {
                guard let imageData = image.jpegData(compressionQuality: 1) else {
                    throw MealImagePreparationError.compressionFailed
                }
                return try MealImagePreparationService().prepareImageData(from: imageData)
            }.value
            mealImageDraft.originalData = preparedImage.originalData
            mealImageDraft.compressedJPEGData = preparedImage.compressedJPEGData
            mealImageDraft.state = .readyToAnalyze
        } catch {
            mealImageDraft.state = .failed(AppErrorMessage.message(
                for: error,
                fallback: "We couldn't prepare that photo. Please try a different image."
            ))
        }
    }

    func analyzePreparedMealImage() async {
        dismissComposerKeyboard()
        guard canUseAIFeatures() else {
            mealImageDraft.reset()
            selectedPhotoPickerItem = nil
            return
        }

        guard mealImageDraft.isReadyToSubmit,
              let imageData = mealImageDraft.compressedJPEGData else {
            mealImageDraft.state = .failed("We couldn't prepare that photo. Please try a different image.")
            return
        }

        let goalType = profile.goalType ?? GoalType.defaultValue
        let entryId = UUID().uuidString
        if let previewData = mealImageDraft.previewData {
            timelineViewModel.setLocalImagePreviewData(previewData, for: entryId)
        }
        timelineViewModel.setLocalPreparedImageData(imageData, for: entryId)
        try? await Task.detached(priority: .utility) {
            try MealImageCacheService().saveImageData(imageData, entryId: entryId)
        }.value
        let savedEntry = await composerViewModel.submitMealImage(
            imageData,
            userId: profile.id,
            goal: goalType,
            loggedAt: loggedAtForSelectedDay(),
            entryId: entryId
        )

        if savedEntry != nil {
            timelineViewModel.removeLocalImagePreviewData(for: entryId)
            timelineViewModel.removeLocalPreparedImageData(for: entryId)
            mealImageDraft.reset()
            selectedPhotoPickerItem = nil
        } else {
            // The failed listener row is now the visible source of truth.
        }
    }

    func imageDataForRetryingMealImage(entryId: String) async -> Data? {
        if let imageData = timelineViewModel.localPreparedImageData(for: entryId) {
            return imageData
        }

        return await Task.detached(priority: .utility) {
            MealImageCacheService().imageData(for: entryId)
        }.value
    }

    func prepareMealImageDataOffMain(_ imageData: Data) async throws -> PreparedMealImage {
        try await Task.detached(priority: .userInitiated) {
            try MealImagePreparationService().prepareImageData(from: imageData)
        }.value
    }
}
