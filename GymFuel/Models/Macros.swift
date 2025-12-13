//
//  Macros.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 11/12/2025.
//

import Foundation

struct Macros: Codable, Equatable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
}

extension Macros {
    static let zero = Macros(calories: 0, protein: 0, carbs: 0, fat: 0)
}
