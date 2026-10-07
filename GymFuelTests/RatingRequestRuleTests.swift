//
//  RatingRequestRuleTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("When a saved meal asks for a rating")
struct RatingRequestRuleTests {

    private func meal(mayonnaise: Double?) -> SavedMeal {
        var breakdown = MealFixtures.sampleBreakdown
        breakdown.items[0].components[2].amount?.adjustedQuantity = mayonnaise
        return SavedMeal(
            id: "meal_1",
            userId: "u",
            name: "Chicken sandwich and crisps",
            macros: MealBreakdownCalculator().total(of: breakdown),
            breakdown: breakdown,
            macrosProvenance: .estimated
        )
    }

    @Test("The first corrected meal asks")
    func correctedMealAsks() {
        #expect(RatingRequestRule.shouldRequest(saving: meal(mayonnaise: 1), alreadyRequested: false))
    }

    @Test("A meal saved as Circa guessed it does not")
    func uncorrectedMealDoesNotAsk() {
        #expect(!RatingRequestRule.shouldRequest(saving: meal(mayonnaise: nil), alreadyRequested: false))
    }

    @Test("Typing the original amount back is not a correction")
    func originalAmountDoesNotAsk() {
        #expect(!RatingRequestRule.shouldRequest(saving: meal(mayonnaise: 2), alreadyRequested: false))
    }

    @Test("Once asked on this install, never again")
    func asksOnlyOnce() {
        #expect(!RatingRequestRule.shouldRequest(saving: meal(mayonnaise: 1), alreadyRequested: true))
    }

    @Test("Totals typed over the breakdown leave nothing corrected to show")
    func supersededMealDoesNotAsk() {
        let typed = Macros(calories: 700, protein: 40, carbs: 55, fat: 30)
        let superseded = MealBreakdownCalculator.superseding(meal(mayonnaise: 1), withUserTotal: typed)

        #expect(!RatingRequestRule.shouldRequest(saving: superseded, alreadyRequested: false))
    }
}
