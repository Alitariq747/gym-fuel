//
//  SavedMealsViewModel.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 04/03/2026.
//

import Foundation

@MainActor
final class SavedMealsViewModel: ObservableObject {
    @Published private(set) var savedMeals: [SavedMeal] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    private let service: SavedMealService

    init(service: SavedMealService = FirebaseSavedMealService()) {
        self.service = service
    }

    func loadSavedMeals(userId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            savedMeals = try await service.fetchSavedMeals(for: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveSavedMeal(_ meal: SavedMeal) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            try await service.saveMeal(meal)
            upsertSavedMeal(meal)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateSavedMeal(_ meal: SavedMeal) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            try await service.updateMeal(meal)
            upsertSavedMeal(meal)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteSavedMeal(_ meal: SavedMeal) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            try await service.deleteMeal(userId: meal.userId, mealId: meal.id)
            savedMeals.removeAll { $0.id == meal.id }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func clearErrorMessage() {
        errorMessage = nil
    }

    private func upsertSavedMeal(_ meal: SavedMeal) {
        if let index = savedMeals.firstIndex(where: { $0.id == meal.id }) {
            savedMeals[index] = meal
        } else {
            savedMeals.insert(meal, at: 0)
        }
    }

    func isSavedMeal(name: String, description: String?, macros: Macros) -> Bool {
        let fingerprintValue = fingerprint(name: name, description: description ?? "", macros: macros)
        return savedMeals.contains { fingerprint(for: $0) == fingerprintValue }
    }

    func fingerprint(for savedMeal: SavedMeal) -> String {
        fingerprint(
            name: savedMeal.name,
            description: savedMeal.description ?? "",
            macros: savedMeal.macros
        )
    }

    private func fingerprint(name: String, description: String, macros: Macros) -> String {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let calories = Int(round(macros.calories))
        let protein = Int(round(macros.protein))
        let carbs = Int(round(macros.carbs))
        let fat = Int(round(macros.fat))

        return "\(normalizedName)|\(normalizedDescription)|\(calories)|\(protein)|\(carbs)|\(fat)"
    }
}
extension SavedMealsViewModel {
    func _setSavedMealsForPreview(_ meals: [SavedMeal]) {
        savedMeals = meals
    }
}
