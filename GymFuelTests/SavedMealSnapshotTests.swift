//
//  SavedMealSnapshotTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// `meal-contract.md` §8: a saved meal is a snapshot of a corrected version, not
/// a pointer to the entry it came from. Re-logging copies it; later edits to it
/// never reach entries already logged.
@Suite("The saved-meal snapshot")
struct SavedMealSnapshotTests {

    /// The sample meal with the mayonnaise corrected to one tbsp.
    private var corrected: MealBreakdown {
        var breakdown = MealFixtures.sampleBreakdown
        breakdown.items[0].components[2].amount?.adjustedQuantity = 1
        return breakdown
    }

    private func snapshot(of breakdown: MealBreakdown?) -> SavedMeal {
        SavedMeal(
            id: "meal_1",
            userId: "u",
            name: "Chicken sandwich and crisps",
            description: "with mayo",
            macros: breakdown.map { MealBreakdownCalculator().total(of: $0) } ?? .zero,
            breakdown: breakdown,
            assumptions: ["A 25 g packet of crisps"],
            macrosProvenance: .estimated
        )
    }

    /// What `logSavedMeal` writes.
    private func relogged(_ meal: SavedMeal) -> LogEntryFeedback {
        LogEntryFeedback(
            explanation: "Saved meal logged directly.",
            assumptions: meal.assumptions ?? [],
            confidence: nil,
            macros: meal.macros,
            goalFitScore: nil,
            estimatedItems: nil,
            breakdown: meal.breakdown,
            macrosProvenance: meal.macrosProvenance
        )
    }

    // MARK: - Round trip

    @Test("Re-logging carries the correction, to the digit")
    func correctionSurvivesRelogging() throws {
        let feedback = relogged(snapshot(of: corrected))
        let mayonnaise = try #require(feedback.breakdown?.items[0].components[2].amount)

        #expect(feedback.breakdown == corrected)
        #expect(mayonnaise.adjustedQuantity == 1)
        #expect(mayonnaise.quantity == 2, "the first estimate rode along too")
        #expect(feedback.macros?.calories == 513.5)
    }

    @Test("Re-logging carries the assumptions and the provenance")
    func contextSurvivesRelogging() {
        let feedback = relogged(snapshot(of: corrected))

        #expect(feedback.assumptions == ["A 25 g packet of crisps"])
        #expect(feedback.macrosProvenance == .estimated)
        #expect(MealBreakdownCalculator().assumptions(of: feedback).first == "Full-fat, not light")
    }

    @Test("Every field of a snapshot survives encoding and decoding")
    func snapshotRoundTrips() throws {
        let meal = snapshot(of: corrected)
        let data = try JSONEncoder().encode(meal)

        #expect(try JSONDecoder().decode(SavedMeal.self, from: data) == meal)
    }

    @Test("A saved meal written before Step 5 decodes with no snapshot")
    func olderSavedMealDecodes() throws {
        let json = #"""
        {
          "id": "m", "userId": "u", "name": "Chicken rice bowl",
          "macros": { "calories": 620, "protein": 45, "carbs": 70, "fat": 18 },
          "createdAt": 780000000
        }
        """#
        let data = try #require(json.data(using: .utf8))
        let decoded = try JSONDecoder().decode(SavedMeal.self, from: data)

        #expect(decoded.breakdown == nil)
        #expect(decoded.assumptions == nil)
        #expect(decoded.macros.calories == 620)
    }

    // MARK: - A meal with nothing to snapshot

    @Test("A meal typed by hand logs exactly as it did before, and gains no items")
    func handTypedMealGainsNothing() {
        let typed = SavedMeal(
            id: "m", userId: "u", name: "Porridge",
            macros: Macros(calories: 300, protein: 10, carbs: 50, fat: 5)
        )
        let feedback = relogged(typed)

        #expect(feedback.breakdown == nil)
        #expect(feedback.assumptions.isEmpty)
        #expect(feedback.macros?.calories == 300)
        #expect(feedback.estimatedItems == nil, "no invented component detail")
    }

    // MARK: - Independence

    @Test("Editing the saved meal does not rewrite an entry already logged from it")
    func laterEditsDoNotReachBack() throws {
        let meal = snapshot(of: corrected)
        let alreadyLogged = relogged(meal)

        var edited = meal
        edited.name = "Renamed"
        edited.breakdown?.items[0].components[2].amount?.adjustedQuantity = 2

        #expect(alreadyLogged.breakdown == corrected)
        #expect(try #require(alreadyLogged.breakdown?.items[0].components[2].amount).adjustedQuantity == 1)
    }

    // MARK: - Editing the totals (§6, reused)

    @Test("Retyping a saved meal's totals removes the breakdown it no longer matches")
    func typingTotalsSupersedes() {
        let typed = Macros(calories: 700, protein: 40, carbs: 55, fat: 30)
        let result = MealBreakdownCalculator.superseding(snapshot(of: corrected), withUserTotal: typed)

        #expect(result.breakdown == nil)
        #expect(result.assumptions == nil)
        #expect(result.macros == typed)
        #expect(result.macrosProvenance == .userTotal)
    }

    @Test("An override keeps the meal's identity, which is not analysis")
    func overrideKeepsIdentity() {
        let meal = snapshot(of: corrected)
        let result = MealBreakdownCalculator.superseding(
            meal,
            withUserTotal: Macros(calories: 700, protein: 40, carbs: 55, fat: 30)
        )

        #expect(result.id == meal.id)
        #expect(result.name == meal.name)
        #expect(result.description == meal.description)
        #expect(result.createdAt == meal.createdAt)
    }

    /// The bug this guards: both editors round for display, so comparing a typed
    /// 33 against a stored 32.7 would read every untouched save as an override.
    @Test("Saving without touching a field is not an override")
    func roundedEqualityIsNotAnOverride() {
        let stored = Macros(calories: 607, protein: 32.7, carbs: 42.4, fat: 33.7)
        let asShown = Macros(calories: 607, protein: 33, carbs: 42, fat: 34)

        #expect(asShown.rounded() == stored.rounded())
        #expect(asShown != stored, "they differ exactly — only the rounded forms agree")
    }
}
