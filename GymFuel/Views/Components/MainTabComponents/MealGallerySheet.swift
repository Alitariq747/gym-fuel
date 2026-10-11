import PhotosUI
import SwiftUI

struct MealGallerySheet: View {
    let item: PhotosPickerItem
    let isDismissing: Bool
    let onClose: () -> Void
    let onDismissed: () -> Void
    let onUsePhoto: (ConfirmedMealPhoto, MealImageSource) -> Void
    @StateObject private var review = MealPhotoReviewModel(source: .photoLibrary)
    @State private var replacement: PhotosPickerItem?
    @State private var showsPicker = false

    var body: some View {
        // Always reviewing: the photo is picked before the panel opens.
        MealPhotoPanel(
            isReviewing: true, isExpanded: review.hasUsedPhoto,
            isDocked: review.isEditingDescription, isDismissing: isDismissing,
            onClose: close, onDismissed: onDismissed
        ) {
            MealPhotoReviewView(model: review, onReplace: {
                showsPicker = true
            }, onUsePhoto: { photo in
                onUsePhoto(photo, .photoLibrary)
            })
        }
        .photosPicker(isPresented: $showsPicker, selection: $replacement,
                      matching: .images, preferredItemEncoding: .current)
        .onAppear { prepare(item) }
        .onChange(of: replacement) { _, _ in consumeReplacement() }
        .onChange(of: showsPicker) { _, _ in consumeReplacement() }
        .onChange(of: isDismissing) { _, closing in
            if closing { review.cancelPendingWork() }
        }
        .onDisappear { review.clearSelection() }
    }

    private func prepare(_ item: PhotosPickerItem) {
        guard !isDismissing else { return }
        review.select {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw MealImagePreparationError.invalidImageData
            }
            return data
        }
    }

    /// Cancelling the picker keeps the current photo.
    private func consumeReplacement() {
        guard !showsPicker, let item = replacement else { return }
        replacement = nil
        prepare(item)
    }

    private func close() {
        review.cancelPendingWork()
        onClose()
    }
}
