import ImageIO
import SwiftUI

struct MealPhotoReviewView: View {
    @ObservedObject var model: MealPhotoReviewModel
    let onReplace: () -> Void
    let onUsePhoto: (PreparedMealImage) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var preview: UIImage?

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
                }
                .clipShape(RoundedRectangle(cornerRadius: Circa.Radius.cardSmall))
                .overlay {
                    RoundedRectangle(cornerRadius: Circa.Radius.cardSmall)
                        .strokeBorder(Color.circaCardBorder, lineWidth: Circa.Rule.hairline)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Selected meal photo")
            }
            .frame(minHeight: 80)

            if model.draft.state == .preparing {
                ProgressView("Preparing photo…")
                    .font(.circaCaption)
                    .tint(Color.circaInk2)
            }
            if let message = model.draft.failureMessage {
                Text(message)
                    .font(.circaBody)
                    .foregroundStyle(Color.circaDanger)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Retry") { model.retry() }
                    .buttonStyle(.circa(.link))
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
                    if let image = model.confirm() { onUsePhoto(image) }
                } label: {
                    Text("Use Photo")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.circa(.primary))
                .disabled(!model.canConfirm)
                .opacity(model.canConfirm ? 1 : 0.45)
                .accessibilityHint("Logs this photo and estimates your meal.")
            }
        }
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
