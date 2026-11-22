import SwiftUI

struct TimelineEntryRow: View {
    let entry: LogEntry
    var localPreviewData: Data? = nil
    var onRetry: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    @State private var statusElapsed = 0
    @State private var statusTask: Task<Void, Never>?
    /// When this row started estimating; the well's ring fills from it.
    @State private var estimateStart: Date?
    @Environment(\.dynamicTypeSize) private var typeSize
    private let settleAnimationDuration = 0.3

    private var rowState: TimelineEntryRowState {
        TimelineEntryRowState(entry: entry, localPreviewData: localPreviewData)
    }

    /// nil once the meal has landed or failed.
    private var estimatingStatus: String? {
        entry.status == .analyzing ? MealCopy.estimatingStatus(elapsedSeconds: statusElapsed) : nil
    }

    /// Counts the estimate's seconds a status step at a time. Paused while the
    /// row is off screen, so coming back doesn't restart the lines.
    private func syncStatusClock() {
        guard entry.status == .analyzing else {
            statusTask?.cancel()
            statusTask = nil
            statusElapsed = 0
            estimateStart = nil
            return
        }

        if estimateStart == nil { estimateStart = .now }
        guard statusTask == nil else { return }
        statusTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(MealCopy.statusStepSeconds))
                guard !Task.isCancelled else { return }
                statusElapsed += MealCopy.statusStepSeconds
            }
        }
    }

    var body: some View {
        Group {
            if entry.status == .failed {
                failedCard
            } else {
                entryRow
            }
        }
        .animation(.easeInOut(duration: settleAnimationDuration), value: entry.status)
        // A faint tick as each line changes. The landing's tap is the
        // timeline's success pattern (TimelineViewModel), so the finish differs.
        .sensoryFeedback(.selection, trigger: estimatingStatus) { old, new in
            old != nil && new != nil
        }
        .onAppear {
            syncStatusClock()
        }
        .onDisappear {
            statusTask?.cancel()
            statusTask = nil
        }
        .onChange(of: entry.status) { _, _ in
            syncStatusClock()
        }
    }

    /// One row in both states, so its parts settle in place over the rule that
    /// is already there, rather than the row being swapped.
    private var entryRow: CircaEntryRow {
        entry.status == .analyzing ? analysingRow : settledRow
    }

    // MARK: - Settled

    /// A meal that has landed. The whole row is the kit's — including the
    /// certainty rule under the number and the AX3 vertical layout, neither of
    /// which this screen re-solves.
    private var settledRow: CircaEntryRow {
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

    /// The photo. The kit owns the well, its radius, the AX3 drop and the ring
    /// drawn over the photo while it is read.
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
                    size: Circa.entryWell
                )
            }
        }
        .frame(width: Circa.entryWell, height: Circa.entryWell)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: Circa.Radius.thumb, style: .continuous))
    }

    /// The same well, for the failure card, which draws its own leading.
    private var photoWell: some View {
        let shape = RoundedRectangle(cornerRadius: Circa.Radius.thumb, style: .continuous)

        return shape
            .fill(Color.circaMediaWell)
            .frame(width: Circa.entryWell, height: Circa.entryWell)
            .overlay { photoContent.clipShape(shape) }
    }

    // MARK: - Analysing

    /// Built from the `Analysing · text + photo` artboard. The same row, the same
    /// well and the same place for the number — only the number is missing, and
    /// the rule is already holding its spot (design.md rule 1).
    private var analysingRow: CircaEntryRow {
        CircaEntryRow(
            title: rowState.isAnalyzingImageEntry ? "Working out your meal" : entry.rawInput,
            calories: nil,
            certainty: .pending,
            meta: MealCopy.estimatingStatus(elapsedSeconds: statusElapsed),
            leading: leading,
            isAnalysing: true,
            estimateStart: estimateStart
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
                    Text(rowState.isMealImageEntry ? "Not estimated yet" : displayTitle)
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
