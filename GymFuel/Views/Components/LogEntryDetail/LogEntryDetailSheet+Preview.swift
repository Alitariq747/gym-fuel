import SwiftUI

private struct PreviewSavedMealService: SavedMealService {
    func fetchSavedMeals(for userId: String) async throws -> [SavedMeal] { [] }
    func saveMeal(_ meal: SavedMeal) async throws { }
    func updateMeal(_ meal: SavedMeal) async throws { }
    func deleteMeal(userId: String, mealId: String) async throws { }
}

#Preview {
    NavigationStack {
        LogEntryDetailSheet(
            entry: LogEntry(
                userId: "preview",
                title: "Chicken Bowl",
                rawInput: "Chicken bowl with some salad and fruits with one cup of boiled rice",
                feedback: LogEntryFeedback(
                    explanation: "High protein and moderate calories fit well into the day.",
                    assumptions: [
                        "Rice was treated as roughly 1 cooked cup.",
                        "Salad dressing was assumed to be light and not separately logged.",
                    ],
                    confidence: 0.72,
                    macros: Macros(calories: 620, protein: 44, carbs: 52, fat: 20)
                )
            )
        )
        .environmentObject(SavedMealsViewModel(service: PreviewSavedMealService()))
    }
}
