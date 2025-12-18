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
    var protein: Double
    var carbs: Double
    var fat: Double

   
    var confidence: Double?
    var warnings: [String]
    var notes: String?
    var assumptions: [String]
    
    
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
    
    enum CodingKeys: String, CodingKey {
           case name, calories, protein, carbs, fat, confidence, warnings, notes, assumptions
       }

       init(from decoder: Decoder) throws {
           let c = try decoder.container(keyedBy: CodingKeys.self)

           name = try c.decodeIfPresent(String.self, forKey: .name)
           calories = try c.decode(Double.self, forKey: .calories)
           protein = try c.decode(Double.self, forKey: .protein)
           carbs = try c.decode(Double.self, forKey: .carbs)
           fat = try c.decode(Double.self, forKey: .fat)

           confidence = try c.decodeIfPresent(Double.self, forKey: .confidence)
           warnings = try c.decodeIfPresent([String].self, forKey: .warnings) ?? []
           notes = try c.decodeIfPresent(String.self, forKey: .notes)
           assumptions = try c.decodeIfPresent([String].self, forKey: .assumptions) ?? []
       }
}

enum MealParseValidationError: Error {
    case negativeValues
    case implausibleCalories(calories: Double, macroKcal: Double)
}

let demo: ParsedMeal = ParsedMeal(
        name: "Oatmeal with Peanut Butter & Banana",
        calories: 600,
        protein: 30,
        carbs: 70,
        fat: 15,
        confidence: 0.87,
        warnings: [
            "Calories and macros are estimates based on typical portions.",
            "Peanut butter quantity assumed as 2 tablespoons."
        ],
        notes: "Good pre-workout meal with balanced carbs and protein.",
        assumptions: [
            "Oats: 60g dry weight",
            "Peanut butter: 2 tbsp",
            "Banana: 1 medium",
            "Milk: 200 ml semi-skimmed"
        ]
    )
