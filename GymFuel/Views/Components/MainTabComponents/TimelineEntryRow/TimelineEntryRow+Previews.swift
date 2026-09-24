import SwiftUI

#Preview("Food") {
    TimelineEntryRow(
        entry: LogEntry(
            userId: "preview",
            title: "Chicken Burrito Bowl",
            rawInput: "Chicken burrito bowl",
            feedback: LogEntryFeedback(
                explanation: "Estimated as one bowl of chicken, rice and vegetables.",
                assumptions: [],
                confidence: 0.84,
                macros: Macros(calories: 620, protein: 44, carbs: 52, fat: 20)
            )
        )
    )
    .padding()
    .circaPaper()
}

#Preview("Image Food") {
    TimelineEntryRow(
        entry: LogEntry(
            userId: "preview",
            source: .image,
            title: "Salmon Rice Bowl",
            rawInput: "Meal image",
            feedback: LogEntryFeedback(
                explanation: "Estimated as one bowl of salmon and cooked rice.",
                assumptions: [],
                confidence: 0.82,
                macros: Macros(calories: 710, protein: 42, carbs: 68, fat: 28)
            )
        ),
        localPreviewData: UIImage(systemName: "fork.knife.circle.fill")?.pngData()
    )
    .padding()
    .circaPaper()
}

private func analysingEntry(source: LogEntrySource) -> LogEntry {
    LogEntry(
        userId: "preview",
        source: source,
        status: .analyzing,
        title: source == .image ? "Analyzing meal image" : "Analyzing entry",
        rawInput: source == .image ? "Meal image" : "two roti, chicken karahi, half a katori rice"
    )
}

private func failedEntry(source: LogEntrySource) -> LogEntry {
    LogEntry(
        userId: "preview",
        source: source,
        status: .failed,
        title: source == .image ? "" : "two roti, chicken karahi, half a katori rice",
        rawInput: source == .image ? "Meal image" : "two roti, chicken karahi, half a katori rice",
        feedback: LogEntryFeedback(
            explanation: "You're offline. Reconnect and try again.",
            assumptions: [],
            confidence: nil,
            macros: nil
        )
    )
}

//private var statesPreview: some View {
//    VStack(alignment: .leading, spacing: 0) {
//        TimelineEntryRow(entry: analysingEntry(source: .text))
//        TimelineEntryRow(
//            entry: analysingEntry(source: .image),
//            localPreviewData: UIImage(systemName: "photo.fill")?.pngData()
//        )
//        TimelineEntryRow(entry: failedEntry(source: .text), onRetry: {}, onDelete: {})
//        TimelineEntryRow(
//            entry: failedEntry(source: .image),
//            localPreviewData: UIImage(systemName: "photo.fill")?.pngData(),
//            onRetry: {},
//            onDelete: {}
//        )
//    }
//    .padding(.vertical)
//    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//    .circaPaper()
//}
//
//#Preview("Analysing and failed") {
//    statesPreview
//}
//
//#Preview("Analysing and failed · dark") {
//    statesPreview
//        .preferredColorScheme(.dark)
//}
//
//#Preview("Analysing and failed · AX3") {
//    ScrollView { statesPreview }
//        .dynamicTypeSize(.accessibility3)
//        .circaPaper()
//}
