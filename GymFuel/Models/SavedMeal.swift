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
    var lastUsedAt: Date?

    init(
        id: String,
        userId: String,
        name: String,
        description: String? = nil,
        macros: Macros,
        createdAt: Date = Date(),
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.macros = macros
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
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
