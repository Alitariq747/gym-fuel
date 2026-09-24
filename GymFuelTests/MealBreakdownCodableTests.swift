//
//  MealBreakdownCodableTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// `meal-contract.md` §2: a field the client cannot decode does not show an error,
/// it removes the meal from the timeline. Everything here exists to prove that
/// cannot happen — the rest of Step 5 is built on top of it.
@Suite("Meal breakdown decoding")
struct MealBreakdownCodableTests {

    // MARK: - Fixtures

    /// The worked example in `meal-contract.md` §4.
    private let karahi = MealBreakdown(items: [
        MealItem(
            id: "itm_roti",
            name: "Roti",
            amount: MealAmount(quantity: 2, unit: "roti"),
            nutrition: Macros(calories: 239.6, protein: 7.0, carbs: 44.2, fat: 5.1)
        ),
        MealItem(
            id: "itm_karahi",
            name: "Chicken karahi",
            amount: MealAmount(quantity: 1, unit: "katori"),
            components: [
                MealComponent(
                    id: "cmp_chicken",
                    name: "Chicken thigh, boneless",
                    amount: MealAmount(quantity: 150, unit: "g"),
                    nutrition: Macros(calories: 250.4, protein: 25.9, carbs: 0, fat: 16.2)
                ),
                MealComponent(
                    id: "cmp_ghee",
                    name: "Ghee",
                    amount: MealAmount(quantity: 2, unit: "tbsp"),
                    nutrition: Macros(calories: 239.8, protein: 0, carbs: 0, fat: 27.1),
                    assumption: "Ghee, not oil"
                ),
                MealComponent(
                    id: "cmp_masala",
                    name: "Tomato and onion masala",
                    amount: MealAmount(quantity: 100, unit: "g"),
                    nutrition: Macros(calories: 59.7, protein: 1.2, carbs: 7.8, fat: 3.4)
                ),
                // Descriptive: no amount, no nutrition.
                MealComponent(id: "cmp_spices", name: "Whole spices")
            ]
        ),
        MealItem(
            id: "itm_rice",
            name: "Rice, boiled white",
            amount: MealAmount(quantity: 0.5, unit: "katori"),
            nutrition: Macros(calories: 129.5, protein: 2.7, carbs: 28.1, fat: 0.3)
        )
    ])

    private func feedback(with breakdown: MealBreakdown?) -> LogEntryFeedback {
        LogEntryFeedback(
            explanation: "Estimated from typical home portions.",
            confidence: 0.62,
            macros: Macros(calories: 919, protein: 36.8, carbs: 80.1, fat: 52.1),
            breakdown: breakdown,
            macrosProvenance: .estimated
        )
    }

    private func decodeFeedback(_ json: String) throws -> LogEntryFeedback {
        let data = try #require(json.data(using: .utf8))
        return try JSONDecoder().decode(LogEntryFeedback.self, from: data)
    }

    // MARK: - Round trip

    @Test("Every field of a breakdown survives encoding and decoding")
    func breakdownRoundTrips() throws {
        let data = try JSONEncoder().encode(feedback(with: karahi))
        let decoded = try JSONDecoder().decode(LogEntryFeedback.self, from: data)

        #expect(decoded == feedback(with: karahi))
        #expect(decoded.breakdown?.items.count == 3)
        #expect(decoded.breakdown?.items[1].components.count == 4)
    }

    @Test("A user's correction survives encoding and decoding")
    func adjustmentRoundTrips() throws {
        var corrected = karahi
        corrected.items[1].components[1].amount?.adjustedQuantity = 1

        let data = try JSONEncoder().encode(feedback(with: corrected))
        let decoded = try JSONDecoder().decode(LogEntryFeedback.self, from: data)
        let ghee = try #require(decoded.breakdown?.items[1].components[1].amount)

        #expect(ghee.adjustedQuantity == 1)
        #expect(ghee.quantity == 2, "the first estimate is never overwritten")
        #expect(ghee.isAdjusted)
    }

    // MARK: - Documents written before this contract existed

    @Test("A document written before Step 6 still decodes, ignoring its retired key")
    func olderFeedbackDecodes() throws {
        let decoded = try decodeFeedback(#"""
        {
          "explanation": "Estimated from typical portions.",
          "assumptions": ["Two slices of bread"],
          "confidence": 0.7,
          "macros": { "calories": 477, "protein": 32, "carbs": 41, "fat": 21 },
          "goalFitScore": 64,
          "estimatedItems": [
            { "name": "Chicken sandwich", "quantity": "1 sandwich", "estimatedComponents": [] }
          ]
        }
        """#)

        #expect(decoded.breakdown == nil)
        #expect(decoded.macrosProvenance == nil, "which reads as .estimated")
        #expect(decoded.macros?.calories == 477, "the retired key is ignored, not fatal")
        #expect(decoded.explanation == "Estimated from typical portions.")
    }

    // MARK: - The tests that protect the timeline

    @Test("A breakdown whose items are the wrong type decodes as absent, not as a failure")
    func malformedItemsDoesNotThrow() throws {
        let decoded = try decodeFeedback(#"""
        {
          "explanation": "x", "assumptions": [],
          "macros": { "calories": 477, "protein": 32, "carbs": 41, "fat": 21 },
          "breakdown": { "version": 1, "items": "not an array" }
        }
        """#)

        #expect(decoded.breakdown == nil)
        #expect(decoded.macros?.calories == 477, "the entry keeps its totals and stays on the timeline")
    }

    @Test("A breakdown missing its items decodes as absent")
    func missingItemsDoesNotThrow() throws {
        let decoded = try decodeFeedback(#"""
        { "explanation": "x", "assumptions": [], "breakdown": { "version": 1 } }
        """#)

        #expect(decoded.breakdown == nil)
        #expect(decoded.explanation == "x")
    }

    @Test("A malformed node deep inside the tree decodes as absent")
    func malformedNodeDoesNotThrow() throws {
        let decoded = try decodeFeedback(#"""
        {
          "explanation": "x", "assumptions": [],
          "breakdown": { "items": [
            { "id": "a", "name": "Roti", "components": [],
              "amount": { "quantity": "two", "unit": "roti" } }
          ] }
        }
        """#)

        #expect(decoded.breakdown == nil)
        #expect(decoded.explanation == "x")
    }

    @Test("An explicit null breakdown decodes as absent")
    func explicitNullDecodes() throws {
        let decoded = try decodeFeedback(#"""
        { "explanation": "x", "assumptions": [], "breakdown": null }
        """#)

        #expect(decoded.breakdown == nil)
    }

    @Test("A field this build has never heard of is ignored")
    func unknownFieldsIgnored() throws {
        let decoded = try decodeFeedback(#"""
        {
          "explanation": "x", "assumptions": [],
          "breakdown": { "items": [
            { "id": "a", "name": "Roti", "components": [], "servingBasis": "cooked" }
          ], "confidenceBand": "wide" }
        }
        """#)

        #expect(decoded.breakdown?.items.first?.name == "Roti")
    }

    @Test("An unrecognised provenance reads as an estimate, never as more certainty")
    func unknownProvenanceFallsBack() throws {
        let decoded = try decodeFeedback(#"""
        {
          "explanation": "x", "assumptions": [], "macrosProvenance": "labScanned",
          "breakdown": { "items": [
            { "id": "a", "name": "Roti", "components": [], "source": "weighedByUser" }
          ] }
        }
        """#)

        #expect(decoded.macrosProvenance == .estimated)
        #expect(decoded.breakdown?.items.first?.resolvedSource == .estimated)
    }

    @Test("A node with no source at all reads as an estimate")
    func absentSourceResolves() {
        #expect(MealItem(id: "a", name: "Roti").resolvedSource == .estimated)
        #expect(MealComponent(id: "b", name: "Ghee").resolvedSource == .estimated)
    }

    // MARK: - Versioning

    @Test("An absent version reads as the current one and is rendered")
    func absentVersionIsSupported() {
        #expect(karahi.resolvedVersion == MealBreakdown.currentVersion)
        #expect(karahi.isSupported)
    }

    @Test("A breakdown from a later contract is kept but not rendered")
    func laterVersionIsNotSupported() throws {
        let decoded = try decodeFeedback(#"""
        {
          "explanation": "x", "assumptions": [],
          "breakdown": { "version": 9, "items": [
            { "id": "a", "name": "Roti", "components": [] }
          ] }
        }
        """#)
        let breakdown = try #require(decoded.breakdown)

        #expect(breakdown.resolvedVersion == 9)
        #expect(breakdown.isSupported == false, "its fields no longer mean what this build thinks")
    }

    // MARK: - Amounts

    @Test("An uncorrected amount scales by one")
    func scaleDefaultsToOne() {
        let amount = MealAmount(quantity: 2, unit: "tbsp")

        #expect(amount.scale == 1)
        #expect(amount.effectiveQuantity == 2)
        #expect(amount.isAdjusted == false)
    }

    @Test("Halving an amount halves its scale")
    func scaleHalves() {
        let amount = MealAmount(quantity: 2, unit: "tbsp", adjustedQuantity: 1)

        #expect(amount.scale == 0.5)
        #expect(amount.effectiveQuantity == 1)
        #expect(amount.isAdjusted)
    }

    @Test("Removing an ingredient is an amount of zero")
    func removalIsZero() {
        let amount = MealAmount(quantity: 2, unit: "tbsp", adjustedQuantity: 0)

        #expect(amount.scale == 0)
        #expect(amount.isAdjusted)
    }

    @Test("You cannot scale up from nothing")
    func zeroEstimateCannotScale() {
        let amount = MealAmount(quantity: 0, unit: "tbsp", adjustedQuantity: 3)

        #expect(amount.scale == 1, "the only division in the contract is guarded")
    }

    @Test("Correcting an amount back to the original is not an adjustment")
    func revertingIsNotAdjusted() {
        let amount = MealAmount(quantity: 2, unit: "tbsp", adjustedQuantity: 2)

        #expect(amount.isAdjusted == false)
        #expect(amount.scale == 1)
    }

    // MARK: - Macros arithmetic

    @Test("Halving then doubling restores the original numbers exactly")
    func scalingRoundTripsExactly() {
        let original = Macros(calories: 187, protein: 0.3, carbs: 0.2, fat: 20.6)

        #expect(original.scaled(by: 0.5).scaled(by: 2) == original)
    }

    @Test("Summing macros adds every field")
    func summingAddsEveryField() {
        let bread = Macros(calories: 158, protein: 6.1, carbs: 29.4, fat: 2.0)
        let chicken = Macros(calories: 132, protein: 24.8, carbs: 0, fat: 2.9)
        let total = [bread, chicken].reduce(.zero, +)

        #expect(total == Macros(calories: 290, protein: 30.9, carbs: 29.4, fat: 4.9))
    }

    @Test("Rounding is for display and leaves the stored numbers alone")
    func roundingIsDisplayOnly() {
        let exact = Macros(calories: 919.0000000000001, protein: 36.8, carbs: 80.1, fat: 52.1)

        #expect(exact.rounded() == Macros(calories: 919, protein: 37, carbs: 80, fat: 52))
        #expect(exact.calories != 919, "the stored value is untouched")
    }
}
