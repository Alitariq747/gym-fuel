//
//  MealParsingService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/12/2025.
//



import Foundation

protocol MealParsingService {
    func parseMeal(description: String) async throws -> ParsedMeal
}
