//
//  MealParsingService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/12/2025.
//



import Foundation

enum MealParseInput: Equatable {
    case text(description: String)
    case photo(data: Data, mimeType: String, filename: String)
}

protocol MealParsingService {
    func parseMeal(_ input: MealParseInput) async throws -> ParsedMeal
}

extension MealParsingService {
    /// Backward-compatible text entry point while we migrate callers to `MealParseInput`.
    func parseMeal(description: String) async throws -> ParsedMeal {
        try await parseMeal(.text(description: description))
    }
}
