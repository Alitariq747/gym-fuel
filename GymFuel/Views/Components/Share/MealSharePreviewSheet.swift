import SwiftUI

/// The card exactly as it will be sent, then the system share sheet.
struct MealSharePreviewSheet: View {
    let content: MealShareCard.Content
    /// `nil` for a meal with no photo.
    let photoEntryId: String?
    let photoStoragePath: String?

    @Environment(\.dismiss) private var dismiss
    @State private var card: UIImage?
    @State private var isPhotoMissing = false
    @State private var isSharing = false

    var body: some View {
        NavigationStack {
            // The whole card on one screen: it shrinks to fit rather than scroll.
            VStack(spacing: 14) {
                preview
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if isPhotoMissing {
                    note(MealCopy.Share.photoMissing)
                }
                note(MealCopy.Share.privacy)
            }
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.vertical, 8)
            .safeAreaInset(edge: .bottom) {
                if let card {
                    Button {
                        isSharing = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.circa(.primary, height: 52))
                    .padding(.horizontal, Circa.Space.screenMargin)
                    .padding(.bottom, 8)
                    .background {
                        ActivityShareSheet(isPresented: $isSharing, items: [ShareImageItem(image: card, title: content.title)]) { destination in
                            FirebaseTelemetryService.logMealShareEvent(
                                destination == nil ? "cancelled" : "completed",
                                destination: destination?.rawValue
                            )
                        }
                    }
                }
            }
            .background(LinearGradient.circaPaper.ignoresSafeArea())
            .navigationTitle(MealCopy.Share.previewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.circaInk2)
                            .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                            .background(Color.circaWell, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
            }
        }
        .onAppear { FirebaseTelemetryService.logMealShareEvent("preview_opened") }
        .task { await render() }
    }

    @ViewBuilder
    private var preview: some View {
        let shape = RoundedRectangle(cornerRadius: Circa.Radius.card, style: .continuous)
        if let card {
            Image(uiImage: card)
                .resizable()
                .scaledToFit()
                .clipShape(shape)
                .overlay { shape.strokeBorder(Color.circaCardBorder, lineWidth: Circa.Rule.hairline) }
                .accessibilityLabel("Share card: \(content.title)")
        } else {
            shape
                .fill(Color.circaMediaWell)
                .aspectRatio(3 / 4, contentMode: .fit)
        }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.circaCaption)
            .foregroundStyle(Color.circaInk3)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func render() async {
        var photo: UIImage?
        if let photoEntryId {
            photo = await MealImageLoader().image(
                entryId: photoEntryId,
                storagePath: photoStoragePath,
                maxSizeBytes: MealImageLoader.defaultMaxSizeBytes
            )
            isPhotoMissing = photo == nil
        }
        card = MealShareRenderer.image(of: MealShareCard(content: content, photo: photo))
    }
}
