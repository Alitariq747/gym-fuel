import SwiftUI

#Preview("Food") {
    TimelineEntryRow(
        entry: LogEntry(
            userId: "preview",
            title: "Chicken Burrito Bowl",
            rawInput: "Chicken burrito bowl",
            feedback: LogEntryFeedback(
                explanation: "High protein and decent satiety make this easier to fit into a cut.",
                assumptions: [],
                confidence: 0.84,
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
            title: "Salmon Rice Bowl",
            rawInput: "Meal image",
            feedback: LogEntryFeedback(
                explanation: "Balanced protein, carbs, and fats for a steady meal.",
                assumptions: [],
                confidence: 0.82,
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
            title: "Analyzing meal image",
            rawInput: "Meal image"
        ),
        localPreviewData: UIImage(systemName: "photo.fill")?.pngData()
    )
    .padding()
}

#Preview("Failed Text") {
    TimelineEntryRow(
        entry: LogEntry(
            userId: "preview",
            source: .text,
            status: .failed,
            title: "2 eggs and toast",
            rawInput: "2 eggs and toast",
            feedback: LogEntryFeedback(
                explanation: "The meal analysis service is unavailable right now. Try again shortly.",
                assumptions: [],
                confidence: nil,
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
            title: "",
            rawInput: "Meal image",
            feedback: LogEntryFeedback(
                explanation: "The meal analysis service is unavailable right now. Try again shortly.",
                assumptions: [],
                confidence: nil,
                macros: nil,
                goalFitScore: nil,
                estimatedItems: nil
            )
        )
    )
    .padding()
}
