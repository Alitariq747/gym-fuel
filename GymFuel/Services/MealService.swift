//
//  MealService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 12/12/2025.
//

import Foundation

protocol MealService {
    func fetchMeals(for userId: String, dayLogId: String) async throws -> [Meal]
    
    func saveMeal(_ meal: Meal) async throws
    func deleteMeal(_ meal: Meal) async throws
}
