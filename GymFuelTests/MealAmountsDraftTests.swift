//
//  MealAmountsDraftTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("Correcting a meal's amounts")
struct MealAmountsDraftTests {
    private let calculator = MealBreakdownCalculator()

    /// The fixture with its mayonnaise (2 tbsp, 187 kcal) already set to `adjusted`.
    private func meal(mayonnaise adjusted: Double? = nil) -> MealBreakdown {
        var meal = MealFixtures.sampleBreakdown
        meal.items[0].components[2].amount?.adjustedQuantity = adjusted
        return meal
    }

    private func mayonnaise(in breakdown: MealBreakdown?) -> MealAmount? {
        breakdown?.items[0].components[2].amount
    }

    private func typed(_ value: Double) -> String { MealCopy.editableQuantity(value) }

    // MARK: - Save

    @Test("An untouched draft has nothing to save")
    func untouched() {
        let draft = MealAmountsDraft(meal())

        #expect(draft.corrected == meal())
        #expect(!draft.canSave)
        #expect(draft.changedCount == 0)
    }

    @Test("Halving the mayonnaise writes the correction and nothing else")
    func halving() throws {
        var draft = MealAmountsDraft(meal())
        draft.setText(typed(1), for: "cmp_mayonnaise")

        let corrected = try #require(draft.corrected)
        #expect(mayonnaise(in: corrected) == MealAmount(quantity: 2, unit: "tbsp", adjustedQuantity: 1))
        #expect(corrected.items[1] == meal().items[1])
        #expect(draft.canSave)
        #expect(calculator.displayedCalorieDelta(from: draft.opened, to: corrected) == -93)
    }

    @Test("Typing the estimate back clears the correction")
    func estimateBack() {
        var draft = MealAmountsDraft(meal(mayonnaise: 1))
        draft.setText(typed(2), for: "cmp_mayonnaise")

        #expect(mayonnaise(in: draft.corrected)?.adjustedQuantity == nil)
        #expect(draft.canSave)
        #expect(draft.changedCount == 1)
    }

    @Test("A correction undone in the same visit is no change at all")
    func undone() {
        var draft = MealAmountsDraft(meal())
        draft.setText(typed(1), for: "cmp_mayonnaise")
        draft.setText(typed(2), for: "cmp_mayonnaise")

        #expect(!draft.canSave)
        #expect(draft.changedCount == 0)
    }

    @Test("An estimate past two decimals is never corrected to itself")
    func longEstimate() {
        var odd = meal()
        odd.items[0].components[2].amount = MealAmount(quantity: 0.333, unit: "cup")
        #expect(!MealAmountsDraft(odd).canSave)

        odd.items[0].components[2].amount?.adjustedQuantity = 0.5
        var draft = MealAmountsDraft(odd)
        draft.setText(typed(0.333), for: "cmp_mayonnaise")

        #expect(mayonnaise(in: draft.corrected)?.adjustedQuantity == nil)
    }

    @Test("Each changed line counts once, and the delta follows the displayed totals")
    func severalLines() throws {
        var draft = MealAmountsDraft(meal())
        draft.setText(typed(1), for: "cmp_mayonnaise")
        draft.setText(typed(2), for: "itm_crisps")

        let corrected = try #require(draft.corrected)
        #expect(draft.changedCount == 2)
        #expect(calculator.displayedCalorieDelta(from: draft.opened, to: corrected) == 37)
    }

    // MARK: - Empty fields

    @Test("An empty field turns Save off, and the other lines keep their changes")
    func emptyField() {
        var draft = MealAmountsDraft(meal())
        draft.setText(typed(1), for: "cmp_mayonnaise")
        draft.setText("", for: "cmp_bread")

        #expect(draft.corrected == nil)
        #expect(!draft.canSave)
        #expect(!draft.isValid("cmp_bread"))
        #expect(mayonnaise(in: draft.preview)?.adjustedQuantity == 1)
        #expect(draft.preview.items[0].components[0] == meal().items[0].components[0])
    }

    @Test("A field that is not an amount turns Save off")
    func unreadable() {
        var draft = MealAmountsDraft(meal())
        draft.setText("two", for: "cmp_mayonnaise")

        #expect(draft.corrected == nil)
    }

    @Test("A line with nothing to correct has no field")
    func noField() {
        var draft = MealAmountsDraft(meal())
        draft.setText(typed(3), for: "itm_sandwich")
        draft.setText(typed(3), for: "cmp_salad")

        #expect(draft.text["itm_sandwich"] == nil)
        #expect(draft.text["cmp_salad"] == nil)
        #expect(!draft.canSave)
    }
}
