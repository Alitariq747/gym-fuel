import SwiftUI

struct TimelineEntryRow: View {
    let entry: LogEntry
    @Environment(\.colorScheme) private var colorScheme
    var localPreviewData: Data? = nil
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
    @State private var revealSequenceTask: Task<Void, Never>?
    @State private var imageAnalysisMessage = "Analyzing"
    @State private var imageAnalysisMessageTask: Task<Void, Never>?
    @State private var runningSuccessRevealEntryID: String?
    private let revealStepDelay: Duration = .milliseconds(220)
    private let revealAnimationDuration = 0.3
    private let leadingMediaWidth: CGFloat = 72
    private let leadingMediaHeight: CGFloat = 88
    private let leadingSymbolCircleSize: CGFloat = 46

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
    private var isMealImageEntry: Bool {
        let rawInput = entry.rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return entry.type == .food && (
            imageStoragePath != nil ||
            localPreviewData != nil ||
            entry.imageUploadStatus != nil ||
            rawInput == "Meal image"
        )
    }
    private var exerciseEstimate: ExerciseEstimate? {
        feedback?.exercise
    }
    private var exerciseSymbol: String {
        if let activityType = exerciseEstimate?.activityType {
            switch activityType {
            case "walking":
                return "figure.walk"
            case "running":
                return "figure.run"
            case "cycling":
                return "bicycle"
            case "swimming":
                return "figure.pool.swim"
            case "hiking":
                return "figure.hiking"
            case "yoga":
                return "figure.mind.and.body"
            case "rowing":
                return "figure.rower"
            case "hiit":
                return "bolt.heart.fill"
            case "sports":
                return "figure.soccer"
            case "strength_training":
                return "dumbbell.fill"
            default:
                break
            }
        }

        let title = entry.title.lowercased()

        if title.contains("run") || title.contains("treadmill") {
            return "figure.run"
        }
        if title.contains("walk") || title.contains("hike") {
            return "figure.walk"
        }
        if title.contains("cycle") || title.contains("bike") {
            return "bicycle"
        }
        if title.contains("swim") {
            return "figure.pool.swim"
        }
        if title.contains("yoga") || title.contains("stretch") {
            return "figure.mind.and.body"
        }
        if title.contains("box") {
            return "figure.boxing"
        }
        return "dumbbell.fill"
    }

    private func applyImmediateRevealState() {
        showRevealedTitle = true
        showRevealedCalories = hasConsumedMacros || hasBurnedCalories
        showRevealedProtein = hasConsumedMacros
        showRevealedCarbs = hasConsumedMacros
        showRevealedFat = hasConsumedMacros
        showRevealedGoalFit = hasGoalFitScore
    }

    private func resetRevealState() {
        showRevealedTitle = false
        showRevealedCalories = false
        showRevealedProtein = false
        showRevealedCarbs = false
        showRevealedFat = false
        showRevealedGoalFit = false
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
        guard isAnalyzingImageEntry else {
            imageAnalysisMessageTask?.cancel()
            imageAnalysisMessageTask = nil
            imageAnalysisMessage = "Analyzing"
            return
        }

        guard imageAnalysisMessageTask == nil else { return }
        imageAnalysisMessage = "Analyzing"
        imageAnalysisMessageTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run { imageAnalysisMessage = "Crafting Description" }

            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run { imageAnalysisMessage = "Finalising" }
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
                leadingVisual
                    .frame(width: leadingMediaWidth, height: leadingMediaHeight, alignment: .center)
                VStack(alignment: .leading, spacing: 6) {
                    if let statusText {
                        HStack(spacing: 8) {
                            infoChip(statusText)
                        }
                    }
                    if isAnalyzingTextEntry {
                        HStack(alignment: .top, spacing: 10) {
                            Text(entry.rawInput)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(2)
                            Spacer(minLength: 8)
                            MealAnalysisCircularProgress()
                        }
                    } else if isFailedTextEntry {
                        Text(entry.rawInput)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(2)
                    } else if !isAnalyzingImageEntry && !isFailedImageEntry && (entry.status != .succeeded || showRevealedTitle) {
                        HStack(alignment: .top, spacing: 10) {
                            Text(entry.title)
                                .font(.subheadline.bold())
                                .lineLimit(2)
                            Spacer(minLength: 8)
                            Text(entry.loggedAt.formatted(date: .omitted, time: .shortened))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                                .fixedSize()
                        }
                        inlineMetadataRows()
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if hasTrailingAccessory {
                    Spacer(minLength: 12)
                    trailingAccessory
                }
            }
            if let failureMessage, isFailedImageEntry {
                Text(failureMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
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
        .animation(.easeInOut(duration: revealAnimationDuration), value: showRevealedGoalFit)
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

    @ViewBuilder
    private var leadingVisual: some View {
        if entry.type == .exercise {
            leadingSymbol(exerciseSymbol)
        } else if let localPreviewData,
                  let previewImage = UIImage(data: localPreviewData) {
            Image(uiImage: previewImage)
                .resizable()
                .scaledToFill()
                .frame(width: leadingMediaWidth, height: leadingMediaHeight)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else if isMealImageEntry {
            MealImageThumbnailView(
                entryId: entry.id,
                storagePath: imageStoragePath,
                width: leadingMediaWidth,
                height: leadingMediaHeight
            )
        } else if entry.type == .food && !isAnalyzingTextEntry {
            leadingSymbol(entry.source == .savedMeal ? "bookmark" : "square.and.pencil")
        }
    }

    private func leadingSymbol(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 18, weight: .regular))
            .foregroundStyle(Color.primary)
            .frame(width: leadingSymbolCircleSize, height: leadingSymbolCircleSize)
            .background(Color(.systemBackground), in: Circle())
            .overlay {
                Circle()
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04), lineWidth: 1)
            }
    }

    private var hasTrailingAccessory: Bool {
        entry.status == .failed || isAnalyzingImageEntry
    }

    @ViewBuilder
    private var trailingAccessory: some View {
        if entry.status == .failed {
            HStack(spacing: 8) {
                Button(action: { onRetry?() }) {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 30, height: 30)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                Button(action: { onDelete?() }) {
                    Image(systemName: "trash")
                        .frame(width: 30, height: 30)
                        .background(Color.fuelRed.opacity(0.10), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .buttonStyle(.plain)
        } else if isAnalyzingImageEntry {
            MealAnalysisCircularProgress()
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
    private func inlineMetadataRows() -> some View {
        if entry.type == .exercise {
            exerciseMetricRows()
        } else if let macros = feedback?.macros, entry.type == .food,
                  showRevealedCalories || showRevealedProtein || showRevealedCarbs || showRevealedFat {
            VStack(alignment: .leading, spacing: 5) {
                if showRevealedCalories {
                    primaryMetricStat(symbol: "flame.fill", value: "\(Int(macros.calories.rounded())) Calories", color: .primary)
                }
                HStack(spacing: 7) {
                    if showRevealedProtein {
                        secondaryMetricStat(symbol: "fish", value: "\(Int(macros.protein.rounded()))g", color: .fuelBlue)
                    }
                    if showRevealedCarbs {
                        secondaryMetricStat(symbol: "leaf.fill", value: "\(Int(macros.carbs.rounded()))g", color: .fuelGreen)
                    }
                    if showRevealedFat {
                        secondaryMetricStat(symbol: "drop.fill", value: "\(Int(macros.fat.rounded()))g", color: .pink)
                    }
                    if showRevealedGoalFit, let goalFitScore = feedback?.goalFitScore {
                        Spacer(minLength: 8)
                        goalFitScoreBadge(score: goalFitScore)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
            }
            .padding(.top, 1)
        }
    }

    @ViewBuilder
    private func primaryMetricStat(symbol: String, value: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Image(systemName: symbol)
                .font(.caption.weight(.regular))
                .foregroundStyle(color)
            Text(value)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func secondaryMetricStat(symbol: String, value: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.caption2.weight(.regular))
                .foregroundStyle(color.opacity(0.72))
                .frame(width: 14, height: 14)
            Text(value)
                .font(.caption2.weight(.regular))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }

    @ViewBuilder
    private func exerciseSecondaryMetricStat(symbol: String, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.caption2.weight(.regular))
                .foregroundStyle(.primary)
                .frame(width: 14, height: 14)
            Text(value)
                .font(.caption2.weight(.regular))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }

    @ViewBuilder
    private func exerciseMetricRows() -> some View {
        if showRevealedCalories || exerciseEstimate != nil {
            VStack(alignment: .leading, spacing: 6) {
                if showRevealedCalories, let estimatedCalories = feedback?.estimatedCalories {
                    primaryMetricStat(symbol: "flame.fill", value: "\(Int(estimatedCalories.rounded())) Burned", color: .primary)
                }
                if let exerciseEstimate {
                    HStack(spacing: 7) {
                        exerciseSecondaryMetricStat(
                            symbol: exerciseSymbol,
                            value: displayActivityType(exerciseEstimate.activityType)
                        )
                        exerciseSecondaryMetricStat(
                            symbol: "clock.fill",
                            value: "\(exerciseEstimate.durationMinutes) min"
                        )
                        exerciseSecondaryMetricStat(
                            symbol: intensitySymbol(for: exerciseEstimate.intensity),
                            value: displayIntensity(exerciseEstimate.intensity)
                        )
                    }
                    .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                }
            }
            .padding(.top, 1)
        }
    }

    private func displayActivityType(_ value: String) -> String {
        switch value {
        case "walking":
            return "Walking"
        case "running":
            return "Running"
        case "cycling":
            return "Cycling"
        case "strength_training":
            return "Strength"
        case "hiit":
            return "HIIT"
        case "swimming":
            return "Swimming"
        case "sports":
            return "Sports"
        case "rowing":
            return "Rowing"
        case "hiking":
            return "Hiking"
        case "yoga":
            return "Yoga"
        default:
            return "Exercise"
        }
    }

    private func displayIntensity(_ value: String) -> String {
        switch value {
        case "low":
            return "Low"
        case "high":
            return "High"
        default:
            return "Moderate"
        }
    }

    private func intensitySymbol(for value: String) -> String {
        switch value {
        case "low":
            return "gauge.low"
        case "high":
            return "gauge.high"
        default:
            return "gauge.medium"
        }
    }

    @ViewBuilder
    private func goalFitScoreBadge(score: Int) -> some View {
        let color = scoreColor(for: score)
        let symbolName = feedback?.goalType?.symbolName ?? GoalType.defaultValue.symbolName

        HStack(spacing: 4) {
            Image(systemName: symbolName)
                .font(.caption2.weight(.regular))
            Text("\(score)")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .frame(height: 30)
        .background(color.opacity(0.11), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(color.opacity(0.14), lineWidth: 1)
        }
    }

    private func scoreColor(for score: Int) -> Color {
        if score > 80 { return .fuelGreen }
        if score < 50 { return .fuelRed }
        return .fuelBlue
    }


    private var rowBackground: AnyShapeStyle {
        AnyShapeStyle(Color(.systemGray6))
    }

    private var rowStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color(.systemGray5).opacity(0.72)
    }

    private var rowShadow: Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.07)
    }
}



private struct MealAnalysisCircularProgress: View {
    private let cycleDuration = 1.1

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { context in
            let progress = context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: cycleDuration) / cycleDuration

            Circle()
                .fill(Color(.systemBackground).opacity(0.92))
                .frame(width: 26, height: 26)
                .overlay {
                    Circle()
                        .trim(from: 0.12, to: 0.82)
                        .stroke(Color.primary, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                        .rotationEffect(.degrees(progress * 360))
                        .padding(5)
                }
                .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
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
                goalFitScore: 38,
                goalType: .leanBulk,

                estimatedItems: nil
            )
        )
    )
    .padding()
}

#Preview("Image Food") {
    TimelineEntryRow(
        entry: LogEntry(
            userId: "preview",
            source: .image,
            type: .food,
            title: "Salmon Rice Bowl",
            rawInput: "Meal image",
            feedback: LogEntryFeedback(
                explanation: "Balanced protein, carbs, and fats for a steady meal.",
                assumptions: [],
                confidence: 0.82,
                estimatedCalories: nil,
                macros: Macros(calories: 710, protein: 42, carbs: 68, fat: 28),
                goalFitScore: 74,
                goalType: .maintain,
                estimatedItems: nil
            )
        ),
        localPreviewData: UIImage(systemName: "fork.knife.circle.fill")?.pngData()
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
            rawInput: "2 eggs, toast, and coffee, 2 eggs, toast, and coffee, 2 eggs, toast, and coffee, 2 eggs, toast, and coffee"
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
                estimatedItems: nil
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
                estimatedItems: nil
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
            title: "Heavy Back Day",
            rawInput: "45 min treadmill run",
            feedback: LogEntryFeedback(
                explanation: "Moderate-duration cardio session with a reasonable calorie burn estimate.",
                assumptions: [],
                confidence: 0.79,
                estimatedCalories: 410,
                macros: nil,
                goalFitScore: nil,
                estimatedItems: nil,
                exercise: ExerciseEstimate(
                    activityType: "running",
                    durationMinutes: 45,
                    intensity: "high"
                )
            )
        )
    )
    .padding()
}
