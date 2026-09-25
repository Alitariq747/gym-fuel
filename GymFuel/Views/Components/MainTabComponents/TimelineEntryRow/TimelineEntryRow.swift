import SwiftUI

struct TimelineEntryRow: View {
    let entry: LogEntry
    var localPreviewData: Data? = nil
    var onRetry: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    @State private var imageAnalysisMessage = Self.firstImageAnalysisMessage
    @State private var imageAnalysisMessageTask: Task<Void, Never>?
    @Environment(\.dynamicTypeSize) private var typeSize
    private let settleAnimationDuration = 0.3
    private static let firstImageAnalysisMessage = "reading your meal"

    private var rowState: TimelineEntryRowState {
        TimelineEntryRowState(entry: entry, localPreviewData: localPreviewData)
    }

    private func syncImageAnalysisMessageState() {
        guard rowState.isAnalyzingImageEntry else {
            imageAnalysisMessageTask?.cancel()
            imageAnalysisMessageTask = nil
            imageAnalysisMessage = Self.firstImageAnalysisMessage
            return
        }

        guard imageAnalysisMessageTask == nil else { return }
        imageAnalysisMessage = Self.firstImageAnalysisMessage
        imageAnalysisMessageTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run { imageAnalysisMessage = "estimating calories and macros" }

            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run { imageAnalysisMessage = "preparing your summary" }
        }
    }

    var body: some View {
        Group {
            switch entry.status {
            case .succeeded: settledRow
            case .analyzing: analysingRow
            case .failed: failedCard
            }
        }
        // The estimate fades in over the pending rule that is already there.
        // design.md rule 1 — nothing jumps when the number lands, so this is one
        // transition on the value, never a sequence that grows the row.
        .animation(.easeInOut(duration: settleAnimationDuration), value: entry.feedback?.macros)
        .onAppear {
            syncImageAnalysisMessageState()
        }
        .onDisappear {
            imageAnalysisMessageTask?.cancel()
            imageAnalysisMessageTask = nil
        }
        .onChange(of: entry.status) { _, _ in
            syncImageAnalysisMessageState()
        }
    }

    // MARK: - Settled

    /// A meal that has landed. The whole row is the kit's — including the
    /// certainty rule under the number and the AX3 vertical layout, neither of
    /// which this screen re-solves.
    private var settledRow: some View {
        CircaEntryRow(
            title: displayTitle,
            calories: MealCopy.calories(rowState.feedback?.macros),
            certainty: rowState.certainty,
            meta: metaLine,
            assumption: rowState.assumptionLine,
            leading: leading
        )
    }

    /// design.md rule 3 — typed words verbatim, never the model's laundered
    /// `title`. A photo's `rawInput` is the server's description of the plate,
    /// not typed words, so a photo takes `title`.
    private var displayTitle: String {
        let raw = entry.rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return entry.source == .image || raw.isEmpty ? entry.title : raw
    }

    /// `"13:45 · 42P 78C 32F"`, then `saved` for a saved meal.
    private var metaLine: String {
        var parts = [entry.loggedAt.formatted(date: .omitted, time: .shortened)]

        if let macros = rowState.feedback?.macros {
            parts.append(
                "\(Int(macros.protein.rounded()))P \(Int(macros.carbs.rounded()))C \(Int(macros.fat.rounded()))F"
            )
        }

        switch entry.source {
        case .savedMeal: parts.append("saved")
        case .text, .image: break
        }

        return parts.joined(separator: " · ")
    }

    private var leading: CircaEntryLeading {
        guard rowState.isMealImageEntry else {
            return .glyph(entry.source == .savedMeal ? "bookmark" : "square.and.pencil")
        }

        return .photoContent(AnyView(photoContent))
    }

    /// The photo, and the sweep across it while it is being read. The kit owns
    /// the well, its radius and the AX3 drop; only the sweep is this screen's.
    private var photoContent: some View {
        Group {
            if let localPreviewData = rowState.localPreviewData,
               let previewImage = UIImage(data: localPreviewData) {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFill()
            } else {
                MealImageThumbnailView(
                    entryId: entry.id,
                    storagePath: rowState.imageStoragePath,
                    size: Circa.minHitTarget
                )
            }
        }
        .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
        .clipped()
        .overlay {
            if rowState.isAnalyzingImageEntry {
                ImageAnalysisScannerOverlay()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Circa.Radius.thumb, style: .continuous))
    }

    /// The same well, for the failure card, which draws its own leading.
    private var photoWell: some View {
        let shape = RoundedRectangle(cornerRadius: Circa.Radius.thumb, style: .continuous)

        return shape
            .fill(Color.circaMediaWell)
            .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
            .overlay { photoContent.clipShape(shape) }
    }

    // MARK: - Analysing

    /// Built from the `Analysing · text + photo` artboard. The same row, the same
    /// well and the same place for the number — only the number is missing, and
    /// the rule is already holding its spot (design.md rule 1).
    private var analysingRow: some View {
        CircaEntryRow(
            title: rowState.isAnalyzingImageEntry ? "Meal photo" : entry.rawInput,
            calories: nil,
            certainty: .pending,
            meta: rowState.isAnalyzingImageEntry ? imageAnalysisMessage : "estimating",
            leading: leading,
            isAnalysing: true
        )
    }

    // MARK: - Failed

    /// Built from the `Failed · retry` artboard. design.md rule 6 — the sentence
    /// and the photo survive, so the card leads with them and **Try again** costs
    /// the user nothing.
    private var failedCard: some View {
        CircaCard(.danger, radius: Circa.Radius.cardSmall) {
            HStack(alignment: .top, spacing: 11) {
                failedLeading

                VStack(alignment: .leading, spacing: 5) {
                    Text(rowState.isMealImageEntry ? "your photo" : displayTitle)
                        .font(.circaEntryTitle)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(rowState.failureLine)
                        .font(.circaBody)
                        .foregroundStyle(Color.circaDanger)
                        .fixedSize(horizontal: false, vertical: true)

                    // Outside the logging window the callbacks are nil, and a
                    // button that silently does nothing is worse than no button.
                    if onRetry != nil || onDelete != nil {
                        failedActions
                            .padding(.top, 5)
                    }
                }
            }
        }
        .padding(.horizontal, Circa.Space.screenMarginWide)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var failedLeading: some View {
        if rowState.isMealImageEntry {
            photoWell
        } else {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.circaDanger)
                .padding(.top, 2)
        }
    }

    @ViewBuilder
    private var failedActions: some View {
        let tryAgain = Group {
            if let onRetry {
                Button(action: onRetry) {
                    Label("Try again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.circa(.primary))
            }
        }

        let delete = Group {
            if let onDelete {
                Button("Delete", action: onDelete)
                    .buttonStyle(.circa(.quiet))
            }
        }

        // At accessibility sizes the pair stacks rather than shrinking — the
        // 44pt floor is not negotiable (design.md rule 8).
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                tryAgain
                delete
            }
        } else {
            HStack(spacing: 8) {
                tryAgain
                delete
                Spacer(minLength: 0)
            }
        }
    }
}

/// The sweep across a photo that is being read. Paired with `CircaProgressRail`
/// under the row, never with a percentage.
private struct ImageAnalysisScannerOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isScanning = false

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let scannerWidth = max(width * 0.28, 18)

            ZStack(alignment: .leading) {
                Color.clear

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.26),
                                Color.white.opacity(0.18),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: scannerWidth)
                    .offset(x: reduceMotion ? width * 0.36 : (isScanning ? width : -scannerWidth))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            isScanning = false
            withAnimation(.easeInOut(duration: 1.55).repeatForever(autoreverses: false)) {
                isScanning = true
            }
        }
        .onChange(of: reduceMotion) { _, isEnabled in
            if isEnabled { isScanning = false }
        }
    }
}
