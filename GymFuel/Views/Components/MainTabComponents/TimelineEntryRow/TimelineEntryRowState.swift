import Foundation

struct TimelineEntryRowState {
    let entry: LogEntry
    let localPreviewData: Data?

    var feedback: LogEntryFeedback? {
        entry.feedback
    }

    var imageStoragePath: String? {
        entry.image?.storagePath
    }

    var statusText: String? {
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

    var failureMessage: String? {
        guard entry.status == .failed else { return nil }
        return feedback?.explanation ?? "We couldn't process this entry."
    }

    var isAnalyzingTextEntry: Bool {
        entry.status == .analyzing && entry.source == .text
    }

    var isAnalyzingImageEntry: Bool {
        entry.status == .analyzing && entry.source == .image
    }

    var isFailedTextEntry: Bool {
        entry.status == .failed && entry.source == .text
    }

    var isFailedImageEntry: Bool {
        entry.status == .failed && entry.source == .image
    }

    var hasConsumedMacros: Bool {
        feedback?.macros != nil
    }

    var hasGoalFitScore: Bool {
        feedback?.goalFitScore != nil
    }

    /// The one assumption line the row shows, or nil when there is nothing to
    /// say — including after a typed total, which clears both of its sources.
    var assumptionLine: String? {
        let all = MealBreakdownCalculator().assumptions(of: feedback)
        return MealCopy.assumptionLine(count: all.count, lead: all.first)
    }

    /// Whether tapping that line has an editor to open.
    var hasEditableBreakdown: Bool {
        guard let breakdown = feedback?.breakdown else { return false }
        return breakdown.isSupported
    }

    var isMealImageEntry: Bool {
        let rawInput = entry.rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return imageStoragePath != nil ||
            localPreviewData != nil ||
            entry.imageUploadStatus != nil ||
            rawInput == "Meal image"
    }
}
