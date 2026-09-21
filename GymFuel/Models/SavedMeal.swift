//
//  SavedMeal.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 04/03/2026.
//

import Foundation

struct SavedMeal: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    var name: String
    var description: String?
    var macros: Macros
    var createdAt: Date
    /// The corrected version, kept so re-logging costs no AI call and loses none
    /// of the user's work — `meal-contract.md` §8. `nil` on a meal typed by hand,
    /// which is a permanent state and not a legacy one.
    @Lenient var breakdown: MealBreakdown? = nil
    /// The meal-wide assumptions. Node assumptions ride inside `breakdown`.
    var assumptions: [String]? = nil
    /// Carried so a re-logged correction does not present itself as a fresh
    /// estimate, or a typed total as anything but typed.
    var macrosProvenance: MealProvenance? = nil

    init(
        id: String,
        userId: String,
        name: String,
        description: String? = nil,
        macros: Macros,
        createdAt: Date = Date(),
        breakdown: MealBreakdown? = nil,
        assumptions: [String]? = nil,
        macrosProvenance: MealProvenance? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.macros = macros
        self.createdAt = createdAt
        self.breakdown = breakdown
        self.assumptions = assumptions
        self.macrosProvenance = macrosProvenance
    }
}

extension SavedMeal {
    static let demo: SavedMeal = SavedMeal(
        id: UUID().uuidString,
        userId: "demo-user",
        name: "Chicken rice bowl",
        description: "Chicken, rice, avocado, and salsa",
        macros: Macros(calories: 620, protein: 45, carbs: 70, fat: 18),
        createdAt: Date()
    )
}
