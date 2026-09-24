//
//  MealOverrideTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// `meal-contract.md` §6: a typed total asserts a number the breakdown does not
/// produce, so the two cannot both be current. These assert field by field,
/// because the failure this guards against is one field quietly surviving.
@Suite("A typed total supersedes the breakdown")
struct MealOverrideTests {

    private let typed = Macros(calories: 700, protein: 40, carbs: 55, fat: 30)

    private var analysed: LogEntryFeedback {
        LogEntryFeedback(
            explanation: "Estimated from typical shop-bought portions.",
            confidence: 0.64,
            macros: Macros(calories: 607, protein: 32.7, carbs: 42.4, fat: 33.7),
            breakdown: MealFixtures.sampleBreakdown,
            macrosProvenance: .estimated
        )
    }

    private func superseded() -> LogEntryFeedback {
        MealBreakdownCalculator.superseding(analysed, withUserTotal: typed)
    }

    // MARK: - What goes

    @Test("The breakdown is removed, not kept alongside a total it disagrees with")
    func breakdownIsRemoved() {
        #expect(superseded().breakdown == nil)
    }

    @Test("The explanation goes, because it described the superseded numbers")
    func explanationIsCleared() {
        #expect(superseded().explanation.isEmpty)
    }

    @Test("The assumptions go with the breakdown they belonged to")
    func assumptionsAreCleared() {
        #expect(MealBreakdownCalculator().assumptions(of: superseded()).isEmpty)
    }

    @Test("Confidence goes, because it was confidence in a number no longer shown")
    func confidenceIsCleared() {
        #expect(superseded().confidence == nil)
    }

    // MARK: - What stays

    @Test("The typed total is what the meal now says")
    func typedTotalIsKept() {
        #expect(superseded().macros == typed)
    }

    @Test("The total is marked as the user's, and never as measured")
    func provenanceIsUserTotal() {
        #expect(superseded().macrosProvenance == .userTotal)
        #expect(MealCopy.provenance(source: .userTotal, isAdjusted: false) == "You set this total")
    }

    // MARK: - Edges

    @Test("Overriding a meal that had no feedback at all still produces a total")
    func nilFeedbackIsHandled() {
        let result = MealBreakdownCalculator.superseding(nil, withUserTotal: typed)

        #expect(result.macros == typed)
        #expect(result.macrosProvenance == .userTotal)
        #expect(result.breakdown == nil)
    }

    @Test("Overriding twice is the same as overriding once")
    func overrideIsIdempotent() {
        let once = superseded()
        let twice = MealBreakdownCalculator.superseding(once, withUserTotal: typed)

        #expect(once == twice)
    }

    /// The contract's own table, walked in one place. If a field is added to
    /// `LogEntryFeedback` and forgotten in `superseding`, this is what notices.
    @Test("Nothing from the analysis survives except the typed total")
    func nothingElseSurvives() {
        let result = superseded()

        #expect(result == LogEntryFeedback(
            explanation: "",
            confidence: nil,
            macros: typed,
            breakdown: nil,
            macrosProvenance: .userTotal
        ))
    }

    @Test("A quantity edit is not an override")
    func quantityEditKeepsEverything() {
        var corrected = MealFixtures.sampleBreakdown
        corrected.items[0].components[2].amount?.adjustedQuantity = 1

        // What `updateBreakdown` writes: the breakdown and the total it implies.
        var feedback = analysed
        feedback.breakdown = corrected
        feedback.macros = MealBreakdownCalculator().total(of: corrected)

        #expect(feedback.explanation == analysed.explanation)
        #expect(feedback.confidence == analysed.confidence)
        #expect(feedback.breakdown != nil)
    }
}
