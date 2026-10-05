import ImageIO
import SwiftUI

struct MealPhotoReviewView: View {
    @ObservedObject var model: MealPhotoReviewModel
    let onReplace: () -> Void
    let onUsePhoto: (ConfirmedMealPhoto) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var preview: UIImage?
    @State private var photoWidth: CGFloat = 0

    private var previewData: Data? { model.draft.compressedJPEGData ?? model.draft.originalData }

    var body: some View {
        AdaptiveScrollContainer { reviewContent }
            .foregroundStyle(Color.circaInk2)
            .task(id: previewData) { await loadPreview() }
    }

    private var reviewContent: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                ZStack {
                    Color.circaMediaWell
                    if let preview {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(Color.circaInk3)
                    }
                    if model.draft.state == .analyzing {
                        ImageAnalysisScannerOverlay()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Circa.Radius.cardSmall))
                .overlay {
                    RoundedRectangle(cornerRadius: Circa.Radius.cardSmall)
                        .strokeBorder(Color.circaCardBorder, lineWidth: Circa.Rule.hairline)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Selected meal photo")
                .accessibilityValue(model.draft.state == .analyzing ? "Reading your photo" : "")
            }
            .frame(minHeight: 80)
            // Once used, the photo stops filling the card so the scroll view, not the
            // photo, gives way to the keyboard.
            .frame(height: model.hasUsedPhoto && photoWidth > 0 ? photoWidth : nil)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { photoWidth = proxy.size.width }
                        .onChange(of: proxy.size.width) { _, width in photoWidth = width }
                }
            }

            if model.draft.state == .preparing {
                ProgressView("Preparing photo…")
                    .font(.circaCaption)
                    .tint(Color.circaInk2)
            }
            if model.isDescribed {
                descriptionField
                    .transition(.opacity)
            }
            if let message = model.draft.failureMessage {
                Text(message)
                    .font(.circaBody)
                    .foregroundStyle(Color.circaDanger)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Retry") { model.retry() }
                    .buttonStyle(.circa(.link))
            }
            if model.hasUsedPhoto {
                Spacer(minLength: 0)
            }
            let layout = typeSize >= .xxxLarge
                ? AnyLayout(VStackLayout(spacing: 8))
                : AnyLayout(HStackLayout(spacing: 12))
            layout {
                Button(action: onReplace) {
                    Text(model.source == .camera ? "Retake" : "Choose another")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.circa(.secondary))
                .disabled(model.isConfirmed)
                Button {
                    if model.isDescribed {
                        if let photo = model.confirm() { onUsePhoto(photo) }
                    } else {
                        model.describePhoto()
                    }
                } label: {
                    Text(model.isDescribed ? "Log Meal" : "Use Photo")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.circa(.primary))
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.45)
                .accessibilityHint(model.isDescribed
                    ? "Estimates your meal from this description."
                    : "Reads the photo so you can check what it found.")
            }
        }
        .animation(.easeInOut(duration: reduceMotion ? 0.15 : 0.25), value: model.isDescribed)
    }

    private var canContinue: Bool { model.isDescribed ? model.canConfirm : model.canDescribe }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            CircaSectionLabel("From your photo")
            TextField("Describe the meal", text: $model.mealDescription, axis: .vertical)
                .font(.circaBody)
                .foregroundStyle(Color.circaInk)
                .textFieldStyle(.plain)
                .lineLimit(2...5)
                .accessibilityLabel("Meal description")
                .accessibilityHint("Edit anything the photo got wrong.")
                .disabled(model.isConfirmed)
                .overlay(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(Color.circaInk)
                        .frame(height: 1)
                        .offset(y: 5)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func loadPreview() async {
        guard let data = previewData else { preview = nil; return }
        let image = await Task.detached(priority: .userInitiated) {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 1600,
                    kCGImageSourceShouldCacheImmediately: true
                  ] as CFDictionary) else { return Optional<UIImage>.none }
            return UIImage(cgImage: thumbnail)
        }.value
        guard !Task.isCancelled else { return }
        preview = image
    }
}
