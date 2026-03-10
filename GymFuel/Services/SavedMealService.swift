//
//  SavedMealService.swift
//  GymFuel
//
//  Created by Codex on 04/03/2026.
//

import Foundation

protocol SavedMealService {
    func fetchSavedMeals(for userId: String) async throws -> [SavedMeal]
    func saveMeal(_ meal: SavedMeal) async throws
    func updateMeal(_ meal: SavedMeal) async throws
    func deleteMeal(userId: String, mealId: String) async throws
}
