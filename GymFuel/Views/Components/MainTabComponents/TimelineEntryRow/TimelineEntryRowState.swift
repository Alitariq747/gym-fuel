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
        entry.type == .food && feedback?.macros != nil
    }

    var hasBurnedCalories: Bool {
        entry.type == .exercise && feedback?.estimatedCalories != nil
    }

    var hasGoalFitScore: Bool {
        entry.type == .food && feedback?.goalFitScore != nil
    }

    var isMealImageEntry: Bool {
        let rawInput = entry.rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return entry.type == .food && (
            imageStoragePath != nil ||
            localPreviewData != nil ||
            entry.imageUploadStatus != nil ||
            rawInput == "Meal image"
        )
    }
}
