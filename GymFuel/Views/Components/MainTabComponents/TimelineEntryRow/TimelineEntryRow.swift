import SwiftUI

struct TimelineEntryRow: View {
    let entry: LogEntry
    var localPreviewData: Data? = nil
    var onRetry: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var shouldAnimateSuccessReveal: Bool = false
    var onSuccessRevealCompleted: (() -> Void)? = nil
    var onTapAssumption: (() -> Void)? = nil
    @State private var showRevealedTitle = false
    @State private var showRevealedCalories = false
    @State private var showRevealedProtein = false
    @State private var showRevealedCarbs = false
    @State private var showRevealedFat = false
    @State private var revealSequenceTask: Task<Void, Never>?
    @State private var imageAnalysisMessage = "Reading your meal"
    @State private var imageAnalysisMessageTask: Task<Void, Never>?
    @State private var runningSuccessRevealEntryID: String?
    private let revealStepDelay: Duration = .milliseconds(220)
    private let revealAnimationDuration = 0.3
    private let leadingMediaWidth: CGFloat = 72
    private let leadingMediaHeight: CGFloat = 88

    private var rowState: TimelineEntryRowState {
        TimelineEntryRowState(entry: entry, localPreviewData: localPreviewData)
    }

    /// The most consequential assumption, on the row — ochre mono, design.md's
    /// assumption colour.
    ///
    /// Tapping it goes straight to the editor. The row is itself one big `Button`,
    /// so if the outer one wins the hit test instead, the tap still opens the
    /// entry: the same destination, one step further away.
    @ViewBuilder
    private func assumptionRow(_ line: String) -> some View {
        if rowState.hasEditableBreakdown, let onTapAssumption {
            Button(action: onTapAssumption) { assumptionText(line) }
                .buttonStyle(.plain)
        } else {
            assumptionText(line)
        }
    }

    private func assumptionText(_ line: String) -> some View {
        Text(line)
            .font(.circaMono)
            .foregroundStyle(Color.circaAccent)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }

    private func applyImmediateRevealState() {
        showRevealedTitle = true
        showRevealedCalories = rowState.hasConsumedMacros
        showRevealedProtein = rowState.hasConsumedMacros
        showRevealedCarbs = rowState.hasConsumedMacros
        showRevealedFat = rowState.hasConsumedMacros
    }

    private func resetRevealState() {
        showRevealedTitle = false
        showRevealedCalories = false
        showRevealedProtein = false
        showRevealedCarbs = false
        showRevealedFat = false
    }

    private func syncRevealStateForCurrentEntry() {
        guard entry.status == .succeeded else {
            revealSequenceTask?.cancel()
            revealSequenceTask = nil
            runningSuccessRevealEntryID = nil
            resetRevealState()
            return
        }

        if shouldAnimateSuccessReveal {
            guard runningSuccessRevealEntryID != entry.id else { return }
            revealSequenceTask?.cancel()
            revealSequenceTask = nil
            runningSuccessRevealEntryID = entry.id
            resetRevealState()
            startSuccessRevealSequence()
        } else {
            revealSequenceTask?.cancel()
            revealSequenceTask = nil
            runningSuccessRevealEntryID = nil
            applyImmediateRevealState()
        }
    }

    private func syncImageAnalysisMessageState() {
        guard rowState.isAnalyzingImageEntry else {
            imageAnalysisMessageTask?.cancel()
            imageAnalysisMessageTask = nil
            imageAnalysisMessage = "Reading your meal"
            return
        }

        guard imageAnalysisMessageTask == nil else { return }
        imageAnalysisMessage = "Reading your meal"
        imageAnalysisMessageTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run { imageAnalysisMessage = "Estimating calories and macros" }

            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run { imageAnalysisMessage = "Preparing your meal summary" }
        }
    }

    private func startSuccessRevealSequence() {
        revealSequenceTask = Task {
            await reveal(\.showRevealedTitle)
            await reveal(\.showRevealedCalories)

            if rowState.hasConsumedMacros {
                await reveal(\.showRevealedProtein)
                await reveal(\.showRevealedCarbs)
                await reveal(\.showRevealedFat)
            }

            runningSuccessRevealEntryID = nil
            onSuccessRevealCompleted?()
        }
    }

    private func reveal(_ keyPath: ReferenceWritableKeyPath<TimelineEntryRow, Bool>) async {
        try? await Task.sleep(for: revealStepDelay)
        guard !Task.isCancelled else { return }
        await MainActor.run {
            self[keyPath: keyPath] = true
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 12) {
                TimelineEntryLeadingVisual(
                    entry: entry,
                    state: rowState,
                    width: leadingMediaWidth,
                    height: leadingMediaHeight
                )
                VStack(alignment: .leading, spacing: 6) {
                    if let statusText = rowState.statusText {
                        HStack(spacing: 8) {
                            infoChip(statusText)
                        }
                    }
                    if rowState.isAnalyzingTextEntry {
                        loadingContent(
                            title: entry.rawInput,
                            status: "Estimating",
                            symbolName: "sparkles"
                        )
                    } else if rowState.isAnalyzingImageEntry {
                        loadingContent(
                            title: "Analyzing",
                            status: imageAnalysisMessage,
                            symbolName: "camera.macro"
                        )
                    } else if rowState.isFailedTextEntry {
                        Text(entry.rawInput)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(2)
                    } else if !rowState.isAnalyzingImageEntry && !rowState.isFailedImageEntry && (entry.status != .succeeded || showRevealedTitle) {
                        HStack(alignment: .top, spacing: 10) {
                            Text(entry.title)
                                .font(.subheadline.bold())
                                .lineLimit(2)
                            Spacer(minLength: 8)
                            Text(entry.loggedAt.formatted(date: .omitted, time: .shortened))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.circaInk2)
                                .fixedSize()
                        }
                        TimelineEntryMetricsView(
                            entry: entry,
                            state: rowState,
                            showRevealedCalories: showRevealedCalories,
                            showRevealedProtein: showRevealedProtein,
                            showRevealedCarbs: showRevealedCarbs,
                            showRevealedFat: showRevealedFat
                        )
                        if let assumptionLine = rowState.assumptionLine {
                            assumptionRow(assumptionLine)
                        }
                    }
                    if entry.status == .analyzing, !rowState.isAnalyzingTextEntry, !rowState.isAnalyzingImageEntry {
                        Text(entry.rawInput == "Meal image" ? "Analyzing your meal image..." : entry.rawInput)
                            .font(.subheadline)
                            .foregroundStyle(Color.circaInk2)
                            .lineLimit(2)
                    } else if let failureMessage = rowState.failureMessage, !rowState.isFailedImageEntry {
                        Text(failureMessage)
                            .font(.caption)
                            .foregroundStyle(Color.circaDanger)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if hasTrailingAccessory {
                    Spacer(minLength: 12)
                    trailingAccessory
                }
            }
            if let failureMessage = rowState.failureMessage, rowState.isFailedImageEntry {
                Text(failureMessage)
                    .font(.caption)
                    .foregroundStyle(Color.circaDanger)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(rowStroke, lineWidth: 1)
        )
        .animation(.easeInOut(duration: revealAnimationDuration), value: showRevealedTitle)
        .animation(.easeInOut(duration: revealAnimationDuration), value: showRevealedCalories)
        .animation(.easeInOut(duration: revealAnimationDuration), value: showRevealedProtein)
        .animation(.easeInOut(duration: revealAnimationDuration), value: showRevealedCarbs)
        .animation(.easeInOut(duration: revealAnimationDuration), value: showRevealedFat)
        .onAppear {
            syncRevealStateForCurrentEntry()
            syncImageAnalysisMessageState()
        }
        .onDisappear {
            revealSequenceTask?.cancel()
            revealSequenceTask = nil
            imageAnalysisMessageTask?.cancel()
            imageAnalysisMessageTask = nil
            runningSuccessRevealEntryID = nil
        }
        .onChange(of: entry.id) { _, _ in
            syncRevealStateForCurrentEntry()
        }
        .onChange(of: entry.status) { _, _ in
            syncRevealStateForCurrentEntry()
            syncImageAnalysisMessageState()
        }
        .onChange(of: shouldAnimateSuccessReveal) { _, _ in
            syncRevealStateForCurrentEntry()
        }
    }

    private var hasTrailingAccessory: Bool {
        entry.status == .failed
    }

    @ViewBuilder
    private var trailingAccessory: some View {
        if entry.status == .failed {
            HStack(spacing: 8) {
                Button(action: { onRetry?() }) {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 30, height: 30)
                        .background(Color.circaWell, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                Button(action: { onDelete?() }) {
                    Image(systemName: "trash")
                        .frame(width: 30, height: 30)
                        .background(Color.circaDangerGround, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.circaInk2)
            .buttonStyle(.plain)
        }
    }

    private func loadingContent(title: String, status: String, symbolName: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.circaInk)
                .lineLimit(2)

            AnalysisLoadingStatusLine(text: status, symbolName: symbolName)
                .padding(.top, 1)

            AnalysisProgressRail()
                .padding(.top, 2)
        }
    }

    @ViewBuilder
    private func infoChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.circaInk2)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.circaSunken, in: Capsule())
    }

    private var rowBackground: AnyShapeStyle {
        AnyShapeStyle(Color.circaCard)
    }

    private var rowStroke: Color {
        Color.circaCardBorder
    }
}
