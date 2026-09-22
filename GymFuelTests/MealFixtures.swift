//
//  MealFixtures.swift
//  GymFuelTests
//
//  The meal the contract's rules are checked against. It moved here from the app
//  target in Step 6: the scaffolding that put a breakdown on the timeline is gone
//  now that the backend sends real ones, but the tests still need a meal shaped
//  like `meal-contract.md` §4.
//

import Foundation
@testable import LiftEats

enum MealFixtures {

    /// Covers both branches of the contribution rule at once: a composite item
    /// priced by its parts, a simple item priced by itself, one descriptive
    /// component that contributes nothing, and one reference-backed number beside
    /// three estimated ones — so the meal total rolls up as an estimate.
    static let sampleBreakdown = MealBreakdown(items: [
        MealItem(
            id: "itm_sandwich",
            name: "Chicken sandwich",
            amount: MealAmount(quantity: 1, unit: "sandwich"),
            components: [
                MealComponent(
                    id: "cmp_bread",
                    name: "Bread, white",
                    amount: MealAmount(quantity: 2, unit: "slice"),
                    nutrition: Macros(calories: 158, protein: 6.1, carbs: 29.4, fat: 2.0)
                ),
                MealComponent(
                    id: "cmp_chicken",
                    name: "Chicken breast, roasted",
                    amount: MealAmount(quantity: 80, unit: "g"),
                    nutrition: Macros(calories: 132, protein: 24.8, carbs: 0, fat: 2.9)
                ),
                MealComponent(
                    id: "cmp_mayonnaise",
                    name: "Mayonnaise",
                    amount: MealAmount(quantity: 2, unit: "tbsp"),
                    nutrition: Macros(calories: 187, protein: 0.3, carbs: 0.2, fat: 20.6),
                    assumption: "Full-fat, not light"
                ),
                MealComponent(id: "cmp_salad", name: "Lettuce and tomato")
            ]
        ),
        MealItem(
            id: "itm_crisps",
            name: "Salted crisps",
            amount: MealAmount(quantity: 1, unit: "packet"),
            nutrition: Macros(calories: 130, protein: 1.5, carbs: 12.8, fat: 8.2),
            source: .reference,
            sourceNote: "Pack label, 25 g"
        )
    ])
}
