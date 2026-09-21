//
//  MealFixtures.swift
//  GymFuel
//
//  Created by Ahmad on 21/09/2026.
//

#if DEBUG

import Foundation

/// A meal in the shape Step 6 will send, so Step 5's screens can be built and the
/// correction in `build-order.md`'s done-when — mayonnaise from two tbsp to one —
/// can be walked on a real device before any backend work exists.
///
/// It has to be logged through Firestore rather than shown in a preview, because
/// the thing being proved is *save, quit, reopen, correction intact*.
///
/// Debug-only scaffolding. Step 6 deletes it once the backend sends breakdowns.
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

    /// Totals come from the calculator, never from a literal, so logging this
    /// exercises the contribution rule end to end instead of asserting a number
    /// that could quietly stop matching it.
    static func sampleEntry(userId: String, loggedAt: Date = Date()) -> LogEntry {
        let calculator = MealBreakdownCalculator()
        let macros = calculator.total(of: sampleBreakdown)
        let shown = macros.rounded()

        return LogEntry(
            userId: userId,
            source: .text,
            loggedAt: loggedAt,
            title: "Chicken sandwich and crisps",
            rawInput: "chicken sandwich with mayo, and a packet of crisps",
            detail: "Estimated \(Int(shown.calories)) kcal • P \(Int(shown.protein))g"
                + " • C \(Int(shown.carbs))g • F \(Int(shown.fat))g",
            feedback: LogEntryFeedback(
                explanation: "Estimated from typical shop-bought portions.",
                assumptions: [
                    "Full-fat mayonnaise, not light",
                    "A 25 g packet of crisps"
                ],
                confidence: 0.64,
                macros: macros,
                goalFitScore: 58,
                breakdown: sampleBreakdown,
                macrosProvenance: calculator.provenance(of: sampleBreakdown)
            )
        )
    }
}

#endif
