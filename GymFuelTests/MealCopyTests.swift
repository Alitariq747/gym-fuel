//
//  MealCopyTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// Like `TargetsCopyTests`, these avoid asserting whole formatted strings where a
/// number is involved: the decimal separator comes from the device locale, so
/// "0.5 katori" is only right on some devices. The structure is what is asserted.
@Suite("Meal copy")
struct MealCopyTests {

    private func amount(_ quantity: Double, _ unit: String, adjusted: Double? = nil) -> MealAmount {
        MealAmount(quantity: quantity, unit: unit, adjustedQuantity: adjusted)
    }

    /// The same formatter the copy uses, so an expectation is locale-safe.
    private func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }

    // MARK: - Amounts

    @Test("A whole amount has no decimal point")
    func wholeAmountHasNoPoint() {
        #expect(MealCopy.amount(amount(2, "tbsp")) == "2 tbsp")
        #expect(MealCopy.amount(amount(80, "g")) == "80 g")
    }

    @Test("A fractional amount keeps its fraction")
    func fractionalAmountIsKept() {
        #expect(MealCopy.amount(amount(0.5, "katori")) == "\(number(0.5)) katori")
        #expect(MealCopy.amount(amount(1.5, "tbsp")) == "\(number(1.5)) tbsp")
    }

    @Test("A fraction stops at two places")
    func fractionStopsAtTwoPlaces() {
        // Both round to the same two places, which is the truncation itself —
        // asserted without naming a separator.
        #expect(MealCopy.amount(amount(0.333, "katori")) == MealCopy.amount(amount(0.3334, "katori")))
        #expect(MealCopy.amount(amount(0.333, "katori")) != MealCopy.amount(amount(0.34, "katori")))
    }

    @Test("Amounts are written as numerals, never as fraction glyphs")
    func noFractionGlyphs() throws {
        let half = try #require(MealCopy.amount(amount(0.5, "katori")))

        #expect(!half.contains("½"))
        #expect(!half.contains("⁄"))
        #expect(!half.contains("/"))
    }

    @Test("A corrected amount reads as the corrected number, not the first guess")
    func adjustedAmountWins() {
        #expect(MealCopy.amount(amount(2, "tbsp", adjusted: 1)) == "1 tbsp")
        #expect(MealCopy.amount(amount(2, "tbsp", adjusted: 0)) == "0 tbsp")
    }

    @Test("An amount with nothing to say says nothing")
    func missingAmountIsNil() {
        #expect(MealCopy.amount(nil) == nil)
        #expect(MealCopy.amount(amount(2, "")) == "2")
        #expect(MealCopy.amount(amount(2, "   ")) == "2")
    }

    // MARK: - Calories

    @Test("Calories round once, at the point of display")
    func caloriesRound() {
        #expect(MealCopy.calories(Macros(calories: 513.5, protein: 0, carbs: 0, fat: 0)) == "514")
        #expect(MealCopy.calories(Macros(calories: 919.0000000000001, protein: 0, carbs: 0, fat: 0)) == "919")
        #expect(MealCopy.calories(nil) == nil)
    }

    // MARK: - The delta (§6)

    @Test("The delta line is the difference of the two displayed totals")
    func deltaReadsAsShown() {
        #expect(MealCopy.delta(from: 607, to: 514) == "607 → 514 kcal · −93")
    }

    @Test("Adding calories signs the delta the other way")
    func deltaCanBePositive() {
        #expect(MealCopy.delta(from: 514, to: 607) == "514 → 607 kcal · +93")
    }

    @Test("An edit that changes nothing says so rather than showing a zero")
    func zeroDeltaIsNamed() {
        #expect(MealCopy.delta(from: 607, to: 607) == "607 kcal · no change")
    }

    @Test("The delta uses a real minus sign, not a hyphen")
    func deltaUsesMinusSign() {
        #expect(MealCopy.delta(from: 607, to: 514).contains("−"))
        #expect(!MealCopy.delta(from: 607, to: 514).contains("-"))
    }

    // MARK: - Numbers in and out of a field

    @Test("A field shows an amount without a grouping separator, so it parses back")
    func editableQuantityHasNoGrouping() throws {
        let shown = MealCopy.editableQuantity(1_000)

        #expect(shown == "1000")
        #expect(try #require(MealCopy.quantity(from: shown)) == 1_000)
    }

    @Test("A field drops a trailing zero and keeps a real fraction")
    func editableQuantityIsTidy() throws {
        #expect(MealCopy.editableQuantity(2) == "2")
        #expect(try #require(MealCopy.quantity(from: MealCopy.editableQuantity(0.5))) == 0.5)
    }

    @Test("A typed amount round trips through the field")
    func quantityRoundTrips() throws {
        for value in [0.0, 0.5, 1.0, 1.5, 2.0, 80.0, 150.0] {
            let parsed = MealCopy.quantity(from: MealCopy.editableQuantity(value))
            #expect(try #require(parsed) == value)
        }
    }

    @Test("A decimal point is accepted whatever the device separator is")
    func dotIsAlwaysAccepted() {
        #expect(MealCopy.quantity(from: "0.5") == 0.5 || MealCopy.quantity(from: "0,5") == 0.5)
    }

    @Test("Something that is not a number is not a number")
    func nonNumbersAreRejected() {
        #expect(MealCopy.quantity(from: "") == nil)
        #expect(MealCopy.quantity(from: "two") == nil)
        #expect(MealCopy.quantity(from: "1/2") == nil)
    }

    // MARK: - Provenance (§5)

    @Test("A plain estimate says nothing, because the dotted rule already has")
    func plainEstimateIsSilent() {
        #expect(MealCopy.provenance(source: .estimated, isAdjusted: false) == nil)
    }

    @Test("A corrected estimate credits the user for the amount, not for the number")
    func adjustedEstimateNamesTheAmount() {
        #expect(MealCopy.provenance(source: .estimated, isAdjusted: true) == "You set the amount")
    }

    @Test("A reference names its source")
    func referenceNamesItsSource() {
        #expect(
            MealCopy.provenance(source: .reference, isAdjusted: false, sourceNote: "Pack label, 25 g")
                == "Pack label, 25 g"
        )
    }

    @Test("A corrected reference keeps its source and adds the user's amount")
    func adjustedReferenceKeepsBoth() {
        #expect(
            MealCopy.provenance(source: .reference, isAdjusted: true, sourceNote: "Pack label, 25 g")
                == "Pack label, 25 g, your amount"
        )
    }

    @Test("A reference with no note still says where it came from")
    func referenceWithoutNoteFallsBack() {
        #expect(MealCopy.provenance(source: .reference, isAdjusted: false) == "From a label")
        #expect(MealCopy.provenance(source: .reference, isAdjusted: false, sourceNote: "  ") == "From a label")
    }

    @Test("A typed total says the user set it, and never that it was measured")
    func userTotalIsNamed() throws {
        let line = try #require(MealCopy.provenance(source: .userTotal, isAdjusted: false))

        #expect(line == "You set this total")
        #expect(MealCopy.provenance(source: .userTotal, isAdjusted: true) == line)
    }

    @Test("No provenance line claims a number was measured or verified")
    func nothingClaimsMeasurement() {
        let lines = [
            MealCopy.provenance(source: .estimated, isAdjusted: true),
            MealCopy.provenance(source: .reference, isAdjusted: false, sourceNote: "Pack label"),
            MealCopy.provenance(source: .reference, isAdjusted: true, sourceNote: "Pack label"),
            MealCopy.provenance(source: .userTotal, isAdjusted: false)
        ].compactMap { $0 }

        for line in lines {
            #expect(!line.lowercased().contains("measured"))
            #expect(!line.lowercased().contains("verified"))
            #expect(!line.lowercased().contains("accurate"))
        }
    }

    // MARK: - Failure

    @Test("The reason leads, and what survived follows")
    func failureKeepsTheReason() {
        #expect(
            MealCopy.failure(reason: "You're offline. Reconnect and try again.", preserved: .words)
                == "You're offline. Reconnect and try again. Your words are saved — nothing to retype."
        )
    }

    @Test("A reason without a full stop gets one, and one with a stop keeps just the one")
    func failurePunctuatesOnce() {
        #expect(MealCopy.failure(reason: "Couldn't reach Circa", preserved: .words)
            .hasPrefix("Couldn't reach Circa. Your words"))
        #expect(!MealCopy.failure(reason: "Couldn't reach Circa.", preserved: .words).contains(".."))
        #expect(MealCopy.failure(reason: "Is the plate empty?", preserved: .photo)
            .hasPrefix("Is the plate empty? Your photo"))
    }

    @Test("A missing or blank reason still says something true")
    func failureFallsBack() {
        let expected = "We couldn't reach Circa. Your words are saved — nothing to retype."
        #expect(MealCopy.failure(reason: nil, preserved: .words) == expected)
        #expect(MealCopy.failure(reason: "   \n ", preserved: .words) == expected)
    }

    @Test("A photo failure promises the photo, not the words")
    func failureKeepsThePhoto() {
        let line = MealCopy.failure(reason: "That was too dark to read.", preserved: .photo)
        #expect(line.hasSuffix("Your photo is saved — nothing to re-shoot."))
        #expect(!line.contains("retype"))
    }
}

