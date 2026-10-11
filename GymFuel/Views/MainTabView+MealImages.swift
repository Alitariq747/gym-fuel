import Foundation
import PhotosUI
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
                    if let item = mealLibraryPick {
                        MealGallerySheet(
                            item: item,
                            isDismissing: mealPhotoPresentation.isDismissing,
                            onClose: { mealPhotoPresentation.dismiss() },
                            onDismissed: { submitConfirmedMealPhoto(sessionID: session.id) },
                            onUsePhoto: confirmMealPhoto
                        )
                    }
                }
            }
            .id(session.id)
        }
    }

    private var canStartMealPhoto: Bool {
        !mealPhotoPresentation.isActive && !composerViewModel.isSubmitting && !isSubmittingMealPhoto
    }

    func presentMealPhotoSheet(source: MealImageSource) {
        guard canStartMealPhoto, canUseAIFeatures() else { return }
        dismissComposerKeyboard()
        composerViewModel.clearError()
        mealPhotoPresentation.present(source: source, loggedAt: loggedAtForSelectedDay())
    }

    func presentMealLibrary() {
        guard canStartMealPhoto, canUseAIFeatures() else { return }
        dismissComposerKeyboard()
        mealLibraryPick = nil
        showsMealLibrary = true
    }

    /// The panel opens once the system picker has closed with a photo.
    func openMealLibraryPick() {
        guard !showsMealLibrary, mealLibraryPick != nil else { return }
        presentMealPhotoSheet(source: .photoLibrary)
    }

    func confirmMealPhoto(_ photo: ConfirmedMealPhoto, source: MealImageSource) {
        mealPhotoPresentation.confirm(photo, source: source)
    }

    func submitConfirmedMealPhoto(sessionID: UUID) {
        guard let submission = mealPhotoPresentation.finishDismissal(sessionID: sessionID) else { return }
        isSubmittingMealPhoto = true
        Task {
            defer { isSubmittingMealPhoto = false }
            await analyzePreparedMealImage(submission.photo, loggedAt: submission.loggedAt)
        }
    }

    func analyzePreparedMealImage(_ photo: ConfirmedMealPhoto, loggedAt: Date) async {
        dismissComposerKeyboard()
        guard canUseAIFeatures(), !composerViewModel.isSubmitting else { return }

        let imageData = photo.image.compressedJPEGData
        let goalType = profile.goalType ?? GoalType.defaultValue
        let entryId = UUID().uuidString
        timelineViewModel.setLocalImagePreviewData(imageData, for: entryId)
        timelineViewModel.setLocalPreparedImageData(imageData, for: entryId)
        try? await Task.detached(priority: .utility) {
            try MealImageCacheService().saveImageData(imageData, entryId: entryId)
        }.value
        let savedEntry = await composerViewModel.submitMealImage(
            imageData,
            description: photo.description,
            isDescriptionEdited: photo.isDescriptionEdited,
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
