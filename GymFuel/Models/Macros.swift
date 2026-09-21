//
//  Macros.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 11/12/2025.
//

import Foundation

struct Macros: Codable, Equatable, Hashable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
}

extension Macros {
    static let zero = Macros(calories: 0, protein: 0, carbs: 0, fat: 0)

    static func + (lhs: Macros, rhs: Macros) -> Macros {
        Macros(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat
        )
    }

    /// The same food in a different amount.
    func scaled(by factor: Double) -> Macros {
        Macros(
            calories: calories * factor,
            protein: protein * factor,
            carbs: carbs * factor,
            fat: fat * factor
        )
    }

    /// Display only. `meal-contract.md` §4 stores and sums at full precision and
    /// rounds once at the end, so a shown total is `round(Σ exact)` and never
    /// `Σ round(each)`. The two can differ; the contract bounds that rather than
    /// nudging rows to make a column add up.
    func rounded() -> Macros {
        Macros(
            calories: calories.rounded(),
            protein: protein.rounded(),
            carbs: carbs.rounded(),
            fat: fat.rounded()
        )
    }
}
