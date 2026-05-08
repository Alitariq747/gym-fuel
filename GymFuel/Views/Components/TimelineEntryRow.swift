import SwiftUI

struct TimelineEntryRow: View {
    let entry: LogEntry
    var localPreviewData: Data? = nil
    var showsChevron: Bool = true
    var onRetry: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var shouldAnimateSuccessReveal: Bool = false
    var onSuccessRevealCompleted: (() -> Void)? = nil
    @State private var showRevealedTitle = false
    @State private var showRevealedCalories = false
    @State private var showRevealedProtein = false
    @State private var showRevealedCarbs = false
    @State private var showRevealedFat = false
    @State private var showRevealedGoalFit = false
    @State private var showRevealedExplanation = false
    @State private var revealSequenceTask: Task<Void, Never>?
    @State private var runningSuccessRevealEntryID: String?
    private let revealStepDelay: Duration = .milliseconds(400)
    private let revealAnimationDuration = 0.3

    private var feedback: LogEntryFeedback? { entry.feedback }
    private var imageStoragePath: String? { entry.image?.storagePath }
    private var statusText: String? {
        if entry.status == .analyzing || isFailedTextEntry || isFailedImageEntry {
            return nil
        }
        switch entry.status {
        case .analyzing:
            return "Analyzing..."
        case .failed:
            return "Failed"
        case .succeeded:
            return nil
        }
    }
    private var failureMessage: String? {
        guard entry.status == .failed else { return nil }
        return feedback?.explanation ?? "We couldn't process this entry."
    }
    private var isAnalyzingTextEntry: Bool {
        entry.status == .analyzing && entry.source == .text
    }
    private var isAnalyzingImageEntry: Bool {
        entry.status == .analyzing && entry.source == .image
    }
    private var isFailedTextEntry: Bool {
        entry.status == .failed && entry.source == .text
    }
    private var isFailedImageEntry: Bool {
        entry.status == .failed && entry.source == .image
    }
    private var hasConsumedMacros: Bool {
        entry.type == .food && feedback?.macros != nil
    }
    private var hasBurnedCalories: Bool {
        entry.type == .exercise && feedback?.estimatedCalories != nil
    }
    private var hasGoalFitScore: Bool {
        entry.type == .food && feedback?.goalFitScore != nil
    }
    private var hasRevealExplanation: Bool {
        entry.status != .failed && !(feedback?.explanation.isEmpty ?? true)
    }
    private var showsImagePlaceholder: Bool {
        entry.type == .food && imageStoragePath == nil && localPreviewData == nil && entry.rawInput == "Meal image"
    }
    private var exerciseEmoji: String {
        let title = entry.title.lowercased()

        if title.contains("run") || title.contains("treadmill") {
            return "🏃"
        }
        if title.contains("walk") || title.contains("hike") {
            return "🚶"
        }
        if title.contains("cycle") || title.contains("bike") {
            return "🚴"
        }
        if title.contains("swim") {
            return "🏊"
        }
        if title.contains("yoga") || title.contains("stretch") {
            return "🧘"
        }
        if title.contains("box") {
            return "🥊"
        }
        return "🏋️"
    }

    private func applyImmediateRevealState() {
        showRevealedTitle = true
        showRevealedCalories = hasConsumedMacros || hasBurnedCalories
        showRevealedProtein = hasConsumedMacros
        showRevealedCarbs = hasConsumedMacros
        showRevealedFat = hasConsumedMacros
        showRevealedGoalFit = hasGoalFitScore
        showRevealedExplanation = hasRevealExplanation
    }

    private func resetRevealState() {
        showRevealedTitle = false
        showRevealedCalories = false
        showRevealedProtein = false
        showRevealedCarbs = false
        showRevealedFat = false
        showRevealedGoalFit = false
        showRevealedExplanation = false
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

    private func startSuccessRevealSequence() {
        revealSequenceTask = Task {
            await reveal(\.showRevealedTitle)
            await reveal(\.showRevealedCalories)

            if hasConsumedMacros {
                await reveal(\.showRevealedProtein)
                await reveal(\.showRevealedCarbs)
                await reveal(\.showRevealedFat)
            }

            if hasGoalFitScore {
                await reveal(\.showRevealedGoalFit)
            }

            if hasRevealExplanation {
                await reveal(\.showRevealedExplanation)
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
            HStack(alignment: .top) {
                if entry.type == .exercise {
                    Text(exerciseEmoji)
                        .font(.title3)
                        .frame(width: 38, height: 38)
                        .background(
                            Color(.systemGray6),
                            in: Circle()
                        )
                } else if let imageStoragePath {
                    MealImageThumbnailView(storagePath: imageStoragePath, size: 72)
                } else if let localPreviewData,
                          let previewImage = UIImage(data: localPreviewData) {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else if showsImagePlaceholder {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemGray6))
                        Image(systemName: entry.status == .failed ? "photo.badge.exclamationmark" : "photo")
                            .font(.title3)
                            .foregroundStyle(entry.status == .failed ? .red : .secondary)
                    }
                    .frame(width: 72, height: 72)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(entry.loggedAt.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let statusText {
                            infoChip(statusText)
                        }
                    }
                    if isAnalyzingTextEntry {
                        Text(entry.rawInput)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(2)
                        Divider()
                            .padding(.vertical, 2)
                        HStack(spacing: 0) {
                            Text("🛠️ Analyzing")
                            AnimatedEllipsisView()
                        }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    } else if isFailedTextEntry {
                        Text(entry.rawInput)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(2)
                        Divider()
                            .padding(.vertical, 2)
                    } else if !isAnalyzingImageEntry && !isFailedImageEntry && (entry.status != .succeeded || showRevealedTitle) {
                        Text(entry.title).font(.headline)
                    }
                    if entry.status == .analyzing, !isAnalyzingTextEntry, !isAnalyzingImageEntry {
                        Text(entry.rawInput == "Meal image" ? "Analyzing your meal image..." : entry.rawInput)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else if let failureMessage, !isFailedImageEntry {
                        Text(failureMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .lineLimit(2)
                    }
                    if entry.type == .exercise,
                       showRevealedCalories,
                       let estimatedCalories = feedback?.estimatedCalories {
                        infoChip("🔥 \(Int(estimatedCalories.rounded())) kcals burnt")
                    }
                }
                Spacer(minLength: 12)
                if entry.status == .failed {
                    HStack(spacing: 12) {
                        Button(action: { onRetry?() }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        Button(action: { onDelete?() }) {
                            Image(systemName: "xmark")
                        }
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                } else if showsChevron && entry.status != .analyzing {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            if let macros = feedback?.macros, entry.type == .food,
               showRevealedCalories || showRevealedProtein || showRevealedCarbs || showRevealedFat {
                HStack(spacing: 12) {
                    if showRevealedCalories {
                        macroStat("CAL", value: "\(Int(macros.calories.rounded()))")
                    }
                    if showRevealedProtein {
                        macroStat("PRO", value: "\(Int(macros.protein.rounded()))g")
                    }
                    if showRevealedCarbs {
                        macroStat("CARB", value: "\(Int(macros.carbs.rounded()))g")
                    }
                    if showRevealedFat {
                        macroStat("FAT", value: "\(Int(macros.fat.rounded()))g")
                    }
                }
            }
            if isAnalyzingImageEntry {
                Divider()
                    .padding(.vertical, 2)
                HStack(spacing: 0) {
                    Text("🛠️ Analyzing")
                    AnimatedEllipsisView()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            }
            if let failureMessage, isFailedImageEntry {
                Divider()
                    .padding(.vertical, 2)
                Text(failureMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
            if entry.status != .failed,
               showRevealedExplanation,
               let explanation = feedback?.explanation,
               !explanation.isEmpty {
                Divider()
                    .padding(8)
                HStack(spacing: 12) {
                    if showRevealedGoalFit, let goalFitScore = feedback?.goalFitScore {
                        let scoreColor = goalFitScore >= 60 ? Color.fuelGreen : Color.fuelRed

                        ZStack {
                            Circle()
                                .fill(Color(.systemBackground))
                                .overlay(Circle().stroke(scoreColor))
                            Text("\(goalFitScore)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(scoreColor)
                        }
                        .frame(width: 42, height: 42)
                    }

                    Text(explanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)
//                .background(
//                    Color(.systemBackground),
//                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
//                )
//                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.quaternaryLabel)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(.quaternaryLabel), lineWidth: 1)
        )
        .animation(.easeInOut(duration: revealAnimationDuration), value: showRevealedTitle)
        .animation(.easeInOut(duration: revealAnimationDuration), value: showRevealedCalories)
        .animation(.easeInOut(duration: revealAnimationDuration), value: showRevealedProtein)
        .animation(.easeInOut(duration: revealAnimationDuration), value: showRevealedCarbs)
        .animation(.easeInOut(duration: revealAnimationDuration), value: showRevealedFat)
        .animation(.easeInOut(duration: revealAnimationDuration), value: showRevealedGoalFit)
        .animation(.easeInOut(duration: revealAnimationDuration), value: showRevealedExplanation)
        .onAppear {
            syncRevealStateForCurrentEntry()
        }
        .onChange(of: entry.id) { _, _ in
            syncRevealStateForCurrentEntry()
        }
        .onChange(of: entry.status) { _, _ in
            syncRevealStateForCurrentEntry()
        }
        .onChange(of: shouldAnimateSuccessReveal) { _, _ in
            syncRevealStateForCurrentEntry()
        }
    }

    @ViewBuilder
    private func infoChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemFill), in: Capsule())
    }

    @ViewBuilder
    private func macroStat(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AnimatedEllipsisView: View {
    private let stepDuration = 0.5

    var body: some View {
        TimelineView(.animation(minimumInterval: stepDuration, paused: false)) { context in
            let phase = Int(context.date.timeIntervalSinceReferenceDate / stepDuration) % 4
            Text(String(repeating: ".", count: phase))
                .frame(width: 12, alignment: .leading)
        }
    }
}

#Preview("Food") {
    TimelineEntryRow(
        entry: LogEntry(
            userId: "preview",
            type: .food,
            title: "Chicken Burrito Bowl",
            rawInput: "Chicken burrito bowl",
            feedback: LogEntryFeedback(
                explanation: "High protein and decent satiety make this easier to fit into a cut.",
                assumptions: [],
                confidence: 0.84,
                estimatedCalories: nil,
                macros: Macros(calories: 620, protein: 44, carbs: 52, fat: 20),
                goalFitScore: 68,
                rebalanceHint: nil
            )
        )
    )
    .padding()
}

#Preview("Analyzing Text") {
    TimelineEntryRow(
        entry: LogEntry(
            userId: "preview",
            source: .text,
            status: .analyzing,
            type: .food,
            title: "Analyzing entry",
            rawInput: "2 eggs, toast, and coffee"
        )
    )
    .padding()
}

#Preview("Analyzing Image") {
    TimelineEntryRow(
        entry: LogEntry(
            userId: "preview",
            source: .image,
            status: .analyzing,
            type: .food,
            title: "Analyzing meal image",
            rawInput: "Meal image"
        )
    )
    .padding()
}

#Preview("Failed Text") {
    TimelineEntryRow(
        entry: LogEntry(
            userId: "preview",
            source: .text,
            status: .failed,
            type: .food,
            title: "2 eggs and toast",
            rawInput: "2 eggs and toast",
            feedback: LogEntryFeedback(
                explanation: "The meal analysis service is unavailable right now. Try again shortly.",
                assumptions: [],
                confidence: nil,
                estimatedCalories: nil,
                macros: nil,
                goalFitScore: nil,
                rebalanceHint: nil
            )
        )
    )
    .padding()
}

#Preview("Failed Image") {
    TimelineEntryRow(
        entry: LogEntry(
            userId: "preview",
            source: .image,
            status: .failed,
            type: .food,
            title: "",
            rawInput: "Meal image",
            feedback: LogEntryFeedback(
                explanation: "The meal analysis service is unavailable right now. Try again shortly.",
                assumptions: [],
                confidence: nil,
                estimatedCalories: nil,
                macros: nil,
                goalFitScore: nil,
                rebalanceHint: nil
            )
        )
    )
    .padding()
}

#Preview("Exercise") {
    TimelineEntryRow(
        entry: LogEntry(
            userId: "preview",
            type: .exercise,
            title: "Treadmill Run",
            rawInput: "45 min treadmill run",
            feedback: LogEntryFeedback(
                explanation: "Moderate-duration cardio session with a reasonable calorie burn estimate.",
                assumptions: [],
                confidence: 0.79,
                estimatedCalories: 410,
                macros: nil,
                goalFitScore: nil,
                rebalanceHint: nil
            )
        )
    )
    .padding()
}
