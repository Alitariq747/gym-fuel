import PhotosUI
import SwiftUI

struct MealGallerySheet: View {
    let isDismissing: Bool
    let onClose: () -> Void
    let onDismissed: () -> Void
    let onUsePhoto: (PreparedMealImage, MealImageSource) -> Void
    @StateObject private var review = MealPhotoReviewModel(source: .photoLibrary)
    @State private var selection: [PhotosPickerItem] = []
    @State private var allPhotosSelection: PhotosPickerItem?
    @State private var showsAllPhotos = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        MealPhotoPanel(
            isReviewing: review.isReviewing, isDismissing: isDismissing,
            onClose: close, onDismissed: onDismissed
        ) {
            ZStack {
                if review.isReviewing {
                    MealPhotoReviewView(model: review, onReplace: {
                        selection = []
                        review.clearSelection()
                    }, onUsePhoto: { image in
                        onUsePhoto(image, .photoLibrary)
                    })
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.97)))
                } else {
                    photoGrid.transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: reduceMotion ? 0.15 : 0.25), value: review.isReviewing)
        }
        .photosPicker(isPresented: $showsAllPhotos, selection: $allPhotosSelection,
                      matching: .images, preferredItemEncoding: .current)
        .onChange(of: selection) { _, items in
            guard let item = items.first else { return }
            prepare(item)
        }
        .onChange(of: allPhotosSelection) { _, _ in consumeAllPhotosSelection() }
        .onChange(of: showsAllPhotos) { _, _ in consumeAllPhotosSelection() }
        .onChange(of: isDismissing) { _, closing in
            if closing { review.cancelPendingWork() }
        }
        .onDisappear { review.clearSelection() }
    }

    private var photoGrid: some View {
        PhotosPicker(
            selection: $selection,
            maxSelectionCount: 1,
            selectionBehavior: .continuous,
            matching: .images,
            preferredItemEncoding: .current
        ) { Text("Choose a photo") }
        .photosPickerStyle(.inline)
        .photosPickerDisabledCapabilities([.selectionActions, .search, .collectionNavigation])
        .photosPickerAccessoryVisibility(.hidden)
        .overlay(alignment: .bottom) {
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [.clear, .black.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 100)
                    .allowsHitTesting(false)
                HStack {
                    Button(action: close) { MealPhotoControlLabel(symbol: "chevron.backward") }
                        .accessibilityLabel("Back")
                    Spacer(minLength: 12)
                    Button { showsAllPhotos = true } label: { MealPhotoControlLabel(title: "All Photos") }
                        .accessibilityHint("Browse your photos and albums.")
                }
                .buttonStyle(.plain)
                .padding(24)
            }
        }
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

    private func consumeAllPhotosSelection() {
        guard !showsAllPhotos, let item = allPhotosSelection else { return }
        allPhotosSelection = nil
        prepare(item)
    }

    private func close() {
        review.cancelPendingWork()
        onClose()
    }
}
