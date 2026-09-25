import SwiftUI

struct TimelineEntryRowState {
    let entry: LogEntry
    let localPreviewData: Data?

    var feedback: LogEntryFeedback? {
        entry.feedback
    }

    var imageStoragePath: String? {
        entry.image?.storagePath
    }

    /// What the failure card says: why it failed, then what survived it.
    var failureLine: String {
        MealCopy.failure(
            reason: feedback?.explanation,
            preserved: isMealImageEntry ? .photo : .words
        )
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

    /// design.md rule 1. An adjusted estimate keeps its dotted rule — correcting
    /// an amount removes one source of uncertainty and leaves the rest — and a
    /// saved meal keeps the provenance it was saved with, which is why this does
    /// not test `source == .savedMeal`. Same mapping as `MealBreakdownCard`.
    var certainty: CircaCertainty {
        guard let breakdown = feedback?.breakdown else { return .estimated }
        return MealBreakdownCalculator().provenance(of: breakdown) == .estimated ? .estimated : .known
    }

    /// The one assumption line the row shows, or nil when there is nothing to
    /// say — including after a typed total, which clears both of its sources.
    var assumptionLine: String? {
        let all = MealBreakdownCalculator().assumptions(of: feedback)
        return MealCopy.assumptionLine(count: all.count, lead: all.first)
    }

    var isMealImageEntry: Bool {
        let rawInput = entry.rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return imageStoragePath != nil ||
            localPreviewData != nil ||
            entry.imageUploadStatus != nil ||
            rawInput == LogEntry.photoRawInputPlaceholder
    }
}
