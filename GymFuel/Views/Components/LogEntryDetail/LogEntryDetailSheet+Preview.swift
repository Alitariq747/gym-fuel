import SwiftUI

private struct PreviewSavedMealService: SavedMealService {
    func fetchSavedMeals(for userId: String) async throws -> [SavedMeal] { [] }
    func saveMeal(_ meal: SavedMeal) async throws { }
    func updateMeal(_ meal: SavedMeal) async throws { }
    func deleteMeal(userId: String, mealId: String) async throws { }
}

private struct EntryDetailPreview: View {
    var source: LogEntrySource = .text

    var body: some View {
        NavigationStack {
            LogEntryDetailSheet(
                entry: LogEntry(
                    userId: "preview",
                    source: source,
                    title: "Chicken Bowl",
                    rawInput: "Chicken bowl with some salad and fruits with one cup of boiled rice",
                    feedback: LogEntryFeedback(
                        explanation: "High protein and moderate calories fit well into the day.",
                        confidence: 0.72,
                        macros: Macros(calories: 620, protein: 44, carbs: 52, fat: 20)
                    )
                )
            )
            .environmentObject(SavedMealsViewModel(service: PreviewSavedMealService()))
        }
    }
}

#Preview("Long text") {
    EntryDetailPreview()
}

#Preview("Photo placeholder") {
    EntryDetailPreview(source: .image)
}

#Preview("Dark") {
    EntryDetailPreview().preferredColorScheme(.dark)
}

#Preview("AX3 · narrow", traits: .fixedLayout(width: 320, height: 800)) {
    EntryDetailPreview().environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("RTL") {
    EntryDetailPreview().environment(\.layoutDirection, .rightToLeft)
}
