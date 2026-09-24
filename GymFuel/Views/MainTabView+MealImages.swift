import Foundation
import SwiftUI

extension MainTabView {
    @ViewBuilder
    var mealPhotoOverlay: some View {
        if let session = mealPhotoPresentation.session {
            Group {
                switch session.source {
                case .camera:
                    MealCameraCaptureView(
                        isDismissing: mealPhotoPresentation.isDismissing,
                        onClose: { mealPhotoPresentation.dismiss() },
                        onDismissed: { submitConfirmedMealPhoto(sessionID: session.id) },
                        onUsePhoto: confirmMealPhoto
                    )
                case .photoLibrary:
                    MealGallerySheet(
                        isDismissing: mealPhotoPresentation.isDismissing,
                        onClose: { mealPhotoPresentation.dismiss() },
                        onDismissed: { submitConfirmedMealPhoto(sessionID: session.id) },
                        onUsePhoto: confirmMealPhoto
                    )
                }
            }
            .id(session.id)
        }
    }

    func presentMealPhotoSheet(source: MealImageSource) {
        guard !mealPhotoPresentation.isActive, !composerViewModel.isSubmitting, !isSubmittingMealPhoto,
              canUseAIFeatures() else { return }
        dismissComposerKeyboard()
        composerViewModel.clearError()
        mealPhotoPresentation.present(source: source, loggedAt: loggedAtForSelectedDay())
    }

    func confirmMealPhoto(_ image: PreparedMealImage, source: MealImageSource) {
        mealPhotoPresentation.confirm(image, source: source)
    }

    func submitConfirmedMealPhoto(sessionID: UUID) {
        guard let submission = mealPhotoPresentation.finishDismissal(sessionID: sessionID) else { return }
        isSubmittingMealPhoto = true
        Task {
            defer { isSubmittingMealPhoto = false }
            await analyzePreparedMealImage(submission.image, loggedAt: submission.loggedAt)
        }
    }

    func analyzePreparedMealImage(_ image: PreparedMealImage, loggedAt: Date) async {
        dismissComposerKeyboard()
        guard canUseAIFeatures(), !composerViewModel.isSubmitting else { return }

        let imageData = image.compressedJPEGData
        let goalType = profile.goalType ?? GoalType.defaultValue
        let entryId = UUID().uuidString
        timelineViewModel.setLocalImagePreviewData(imageData, for: entryId)
        timelineViewModel.setLocalPreparedImageData(imageData, for: entryId)
        try? await Task.detached(priority: .utility) {
            try MealImageCacheService().saveImageData(imageData, entryId: entryId)
        }.value
        let savedEntry = await composerViewModel.submitMealImage(
            imageData,
            userId: profile.id,
            goal: goalType,
            loggedAt: loggedAt,
            entryId: entryId
        )

        if savedEntry != nil {
            timelineViewModel.removeLocalImagePreviewData(for: entryId)
            timelineViewModel.removeLocalPreparedImageData(for: entryId)
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
}
