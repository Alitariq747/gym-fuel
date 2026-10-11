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
    @FocusState private var isEditing: Bool

    private let bandHeight: CGFloat = 120
    private var previewData: Data? { model.draft.compressedJPEGData ?? model.draft.originalData }

    // Once used, the photo is square, and a band while typing, so the words
    // keep the room above the keyboard.
    private var photoHeight: CGFloat? {
        guard model.hasUsedPhoto, photoWidth > 0 else { return nil }
        return isEditing ? bandHeight : photoWidth
    }

    var body: some View {
        VStack(spacing: 12) {
            AdaptiveScrollContainer { reviewContent }
            // Outside the scroll view, so the bar rides the keyboard.
            actions
        }
        .foregroundStyle(Color.circaInk2)
        .task(id: previewData) { await loadPreview() }
        .onChange(of: isEditing) { _, editing in model.isEditingDescription = editing }
        .animation(.easeInOut(duration: reduceMotion ? 0.15 : 0.25), value: isEditing)
    }

    private var reviewContent: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                ZStack {
                    Color.circaMediaWell
                    if let preview {
                        Image(uiImage: preview)
                            .resizable()
                            .aspectRatio(contentMode: isEditing ? .fill : .fit)
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
            .frame(height: photoHeight)
            .contentShape(Rectangle())
            .onTapGesture { isEditing = false }
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
            if model.draft.state == .analyzing || model.isDescribed {
                wordsCard
                    .transition(.opacity)
                wordsNote
            }
            if let message = model.draft.failureMessage {
                Text(message)
                    .font(.circaBody)
                    .foregroundStyle(Color.circaDanger)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Retry") { model.retry() }
                    .buttonStyle(.circa(.link))
            }
        }
        .animation(.easeInOut(duration: reduceMotion ? 0.15 : 0.25), value: model.hasUsedPhoto)
        .animation(.easeInOut(duration: reduceMotion ? 0.15 : 0.25), value: model.isDescribed)
    }

    private var actions: some View {
        let layout = typeSize >= .xxxLarge
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            if isEditing {
                CircaHideKeyboardButton { isEditing = false }
            } else {
                Button(action: onReplace) {
                    Text(model.source == .camera ? "Retake" : "Choose another")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.circa(.secondary))
                .disabled(model.isConfirmed)
            }
            Button {
                if model.isDescribed {
                    if let photo = model.confirm() { onUsePhoto(photo) }
                } else {
                    model.describePhoto()
                }
            } label: {
                Group {
                    if model.hasUsedPhoto {
                        Label("Estimate this", systemImage: "sparkles")
                    } else {
                        Text("Use Photo")
                    }
                }
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

    private var canContinue: Bool { model.isDescribed ? model.canConfirm : model.canDescribe }

    /// In place from the moment the photo is read, so the words land where the
    /// dotted lines already are.
    private var wordsCard: some View {
        CircaFieldCard(isFocused: $isEditing) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    CircaSectionLabel(model.isDescriptionEdited ? "Your words" : "From your photo")
                    Spacer(minLength: 0)
                    if !model.isDescribed {
                        MealPhotoReadingStatus()
                    } else if !isEditing {
                        editPill
                    }
                }
                .frame(minHeight: 30)

                if model.isDescribed {
                    TextField("Describe the meal", text: $model.mealDescription,
                              prompt: Text("Describe the meal").foregroundStyle(Color.circaInk3), axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(.title3).weight(.medium))
                        .foregroundStyle(Color.circaInk)
                        .tint(Color.circaAccent)
                        .lineLimit(2...)
                        .submitLabel(.done)
                        .focused($isEditing)
                        .disabled(model.isConfirmed)
                        .onSubmit { isEditing = false }
                        // A vertical field takes Return as a new line; here it means done.
                        .onChange(of: model.mealDescription) { _, text in
                            guard isEditing, text.contains("\n") else { return }
                            model.mealDescription = text.replacingOccurrences(of: "\n", with: "")
                            isEditing = false
                        }
                        .accessibilityLabel("Meal description")
                        .accessibilityHint("Edit anything the photo got wrong.")
                } else {
                    pendingLines
                }
            }
        }
    }

    /// Decoration: the card takes the tap, and the field carries the hint.
    private var editPill: some View {
        Label("Edit", systemImage: "pencil")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.circaAccent)
            .padding(.horizontal, 11)
            .frame(minHeight: 30)
            .background(Color.circaWell, in: Capsule())
            .overlay { Capsule().strokeBorder(Color.circaCardBorder, lineWidth: Circa.Rule.hairline) }
            .accessibilityHidden(true)
    }

    /// design.md rule 1's pending rule, one per line the words will take.
    private var pendingLines: some View {
        VStack(spacing: 24) {
            ForEach([0, 16, 120], id: \.self) { shortfall in
                Color.clear
                    .frame(height: 0)
                    .certaintyRule(.pending)
                    .padding(.trailing, CGFloat(shortfall))
            }
        }
        .padding(.vertical, 10)
        .accessibilityHidden(true)
    }

    private var wordsNote: some View {
        Group {
            if model.isDescribed {
                Text(MealCopy.photoWordsPromise)
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
            } else {
                Text("This takes a few seconds.")
                    .font(.circaMono)
                    .foregroundStyle(Color.circaInk3)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 2)
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

/// What the read is doing. No spinner — design.md rule 1.
private struct MealPhotoReadingStatus: View {
    @State private var start = Date.now

    var body: some View {
        TimelineView(.periodic(from: start, by: 1)) { context in
            Text(MealCopy.photoReadingStatus(elapsedSeconds: Int(context.date.timeIntervalSince(start))))
                .font(.circaMono)
                .foregroundStyle(Color.circaAccent)
        }
    }
}
