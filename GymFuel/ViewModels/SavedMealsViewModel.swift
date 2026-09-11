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
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't load your saved meals. Please try again."
            )
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
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't save that meal. Please try again."
            )
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
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't update that meal. Please try again."
            )
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
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't delete that meal. Please try again."
            )
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
}
extension SavedMealsViewModel {
    func _setSavedMealsForPreview(_ meals: [SavedMeal]) {
        savedMeals = meals
    }
}
