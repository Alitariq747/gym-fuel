//
//  ParsedMeal.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/12/2025.
//


import Foundation

struct ParsedMeal: Codable, Equatable {
   
    var name: String?

   
    var calories: Double
    var protein: Double // grams
    var carbs: Double   // grams
    var fat: Double     // grams

   
    var confidence: Double?      // 0...1
    var warnings: [String]?      // e.g. ["Portion size unclear"]
    var notes: String?           // e.g. "Assumed 2 tbsp olive oil"
}

extension ParsedMeal {
    func validated() throws -> ParsedMeal {
        // Basic sanity
        guard calories >= 0, protein >= 0, carbs >= 0, fat >= 0 else {
            throw MealParseValidationError.negativeValues
        }

       
        let macroKcal = protein * 4 + carbs * 4 + fat * 9
        if calories > 0, macroKcal > 0 {
            let ratio = calories / macroKcal
            // allow wide range because AI estimates vary
            if ratio < 0.4 || ratio > 2.5 {
                throw MealParseValidationError.implausibleCalories(calories: calories, macroKcal: macroKcal)
            }
        }

        return self
    }
}

enum MealParseValidationError: Error {
    case negativeValues
    case implausibleCalories(calories: Double, macroKcal: Double)
}
