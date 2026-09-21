//
//  MealBreakdownCalculatorTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("Meal breakdown totals")
struct MealBreakdownCalculatorTests {
    private let calculator = MealBreakdownCalculator()

    // MARK: - Fixtures

    private func component(
        _ id: String,
        _ name: String,
        _ quantity: Double,
        _ unit: String,
        _ calories: Double,
        adjusted: Double? = nil,
        source: MealProvenance? = nil
    ) -> MealComponent {
        MealComponent(
            id: id,
            name: name,
            amount: MealAmount(quantity: quantity, unit: unit, adjustedQuantity: adjusted),
            nutrition: Macros(calories: calories, protein: 1, carbs: 2, fat: 3),
            source: source
        )
    }

    /// The done-when meal: a composite priced by its parts, beside a simple item
    /// priced by itself.
    private func sandwich(mayonnaise adjusted: Double? = nil) -> MealBreakdown {
        MealBreakdown(items: [
            MealItem(
                id: "itm_sandwich",
                name: "Chicken sandwich",
                amount: MealAmount(quantity: 1, unit: "sandwich"),
                components: [
                    component("cmp_bread", "Bread, white", 2, "slice", 158),
                    component("cmp_chicken", "Chicken breast", 80, "g", 132),
                    component("cmp_mayonnaise", "Mayonnaise", 2, "tbsp", 187, adjusted: adjusted),
                    // Descriptive: no amount, no nutrition.
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

    // MARK: - Contribution

    @Test("A component contributes its stored nutrition scaled to the corrected amount")
    func componentScales() throws {
        let uncorrected = component("a", "Mayonnaise", 2, "tbsp", 187)
        let halved = component("a", "Mayonnaise", 2, "tbsp", 187, adjusted: 1)

        #expect(calculator.contribution(of: uncorrected)?.calories == 187)
        #expect(calculator.contribution(of: halved)?.calories == 93.5)
    }

    @Test("A descriptive component contributes nothing")
    func descriptiveComponentContributesNothing() {
        let salad = MealComponent(id: "a", name: "Lettuce and tomato")

        #expect(calculator.contribution(of: salad) == nil)
    }

    @Test("A descriptive component does not stop its item having a total")
    func descriptiveComponentDoesNotNilTheItem() throws {
        let item = try #require(sandwich().items.first)
        let total = try #require(calculator.contribution(of: item))

        #expect(total.calories == 477)
    }

    /// The double-counting test. If an item ever contributed both its own number
    /// and its components', this is what would catch it.
    @Test("An item with its own nutrition ignores its components entirely")
    func ownNutritionWins() throws {
        let item = MealItem(
            id: "itm",
            name: "Shop sandwich",
            nutrition: Macros(calories: 400, protein: 20, carbs: 40, fat: 15),
            components: [
                component("a", "Bread", 2, "slice", 158),
                component("b", "Filling", 1, "portion", 132)
            ]
        )
        let total = try #require(calculator.contribution(of: item))

        #expect(total.calories == 400, "not 400 + 158 + 132")
    }

    @Test("A component-priced item's own amount does not scale its components")
    func itemAmountDoesNotScaleComponents() throws {
        var breakdown = sandwich()
        breakdown.items[0].amount?.adjustedQuantity = 2
        let item = try #require(breakdown.items.first)

        #expect(
            calculator.contribution(of: item)?.calories == 477,
            "the parts carry the handle, so the same correction is never applied twice"
        )
    }

    @Test("An item with neither nutrition nor priced components has no total")
    func emptyItemHasNoTotal() {
        let item = MealItem(id: "itm", name: "Something", components: [
            MealComponent(id: "a", name: "Unknown")
        ])

        #expect(calculator.contribution(of: item) == nil)
    }

    // MARK: - What can be corrected (§4)

    @Test("A part with a number and an amount can be corrected")
    func pricedPartIsEditable() throws {
        let mayonnaise = try #require(sandwich().items.first?.components[2])

        #expect(mayonnaise.isAmountEditable)
    }

    @Test("A descriptive part has nothing to correct")
    func descriptivePartIsNotEditable() throws {
        let salad = try #require(sandwich().items.first?.components.last)

        #expect(salad.isAmountEditable == false)
    }

    @Test("A simple item carries its own handle")
    func simpleItemIsEditable() throws {
        #expect(sandwich().items[1].isAmountEditable)
    }

    /// The other half of "the same correction is never applied twice": the level
    /// that does not carry the nutrition does not carry the handle either.
    @Test("A component-priced item's own amount is not editable")
    func compositeItemIsNotEditable() throws {
        let composite = try #require(sandwich().items.first)

        #expect(composite.amount != nil, "it still has an amount to show")
        #expect(composite.isAmountEditable == false)
    }

    // MARK: - Meal total

    @Test("The meal total is the sum of its items")
    func mealTotalSumsItems() {
        #expect(calculator.total(of: sandwich()).calories == 607)
    }

    @Test("An empty breakdown totals zero rather than failing")
    func emptyBreakdownIsZero() {
        #expect(calculator.total(of: MealBreakdown(items: [])) == .zero)
    }

    @Test("Correcting one ingredient leaves every other value untouched")
    func correctionIsLocal() throws {
        let before = sandwich()
        let after = sandwich(mayonnaise: 1)

        let beforeItem = try #require(before.items.first)
        let afterItem = try #require(after.items.first)

        for index in [0, 1] {
            #expect(
                calculator.contribution(of: beforeItem.components[index])
                    == calculator.contribution(of: afterItem.components[index]),
                "bread and chicken are identical to the digit"
            )
        }
        #expect(calculator.contribution(of: before.items[1]) == calculator.contribution(of: after.items[1]))
        #expect(calculator.total(of: after).calories == 513.5)
    }

    // MARK: - The delta

    @Test("Halving the mayonnaise shows the difference of the two displayed totals")
    func deltaMatchesWhatIsOnScreen() {
        let before = sandwich()
        let after = sandwich(mayonnaise: 1)

        // 607.0 → 607 and 513.5 → 514, so the footer reads 607 → 514 · −93.
        #expect(calculator.total(of: before).calories.rounded() == 607)
        #expect(calculator.total(of: after).calories.rounded() == 514)
        #expect(calculator.displayedCalorieDelta(from: before, to: after) == -93)
    }

    @Test("Removing an ingredient subtracts all of it")
    func removalSubtractsEverything() {
        let after = sandwich(mayonnaise: 0)

        #expect(calculator.total(of: after).calories == 420)
        #expect(calculator.displayedCalorieDelta(from: sandwich(), to: after) == -187)
    }

    @Test("An edit undone leaves no difference at all")
    func revertedEditHasNoDelta() {
        let before = sandwich()

        #expect(calculator.displayedCalorieDelta(from: before, to: sandwich(mayonnaise: 2)) == 0)
        #expect(calculator.total(of: sandwich(mayonnaise: 2)) == calculator.total(of: before))
    }

    // MARK: - Rounding (§4)

    @Test("A displayed total is the rounded sum, never the sum of rounded rows")
    func totalRoundsOnceAtTheEnd() throws {
        // The worked example in meal-contract.md §4: rows show 240, 550 and 130,
        // which add to 920, while the meal total shows 919. Both are shown as
        // they are — the bound is asserted, not the disagreement hidden.
        let breakdown = MealBreakdown(items: [
            MealItem(id: "a", name: "Roti", nutrition: Macros(calories: 239.6, protein: 7, carbs: 44.2, fat: 5.1)),
            MealItem(id: "b", name: "Chicken karahi", components: [
                component("b1", "Chicken thigh", 150, "g", 250.4),
                component("b2", "Ghee", 2, "tbsp", 239.8),
                component("b3", "Masala", 100, "g", 59.7)
            ]),
            MealItem(id: "c", name: "Rice", nutrition: Macros(calories: 129.5, protein: 2.7, carbs: 28.1, fat: 0.3))
        ])

        let displayedTotal = calculator.total(of: breakdown).calories.rounded()
        let displayedRows = breakdown.items
            .compactMap { calculator.contribution(of: $0)?.calories.rounded() }

        #expect(displayedTotal == 919)
        #expect(displayedRows == [240, 550, 130])
        #expect(displayedRows.reduce(0, +) == 920)
        #expect(
            abs(displayedTotal - displayedRows.reduce(0, +)) <= Double(displayedRows.count) / 2,
            "within the bound §4 commits to"
        )
    }

    // MARK: - Provenance roll-up (§5)

    @Test("One estimate anywhere makes the whole total an estimate")
    func mixedProvenanceStaysEstimated() {
        #expect(calculator.provenance(of: sandwich()) == .estimated)
    }

    @Test("A total is reference-backed only when every number in it is")
    func allReferenceRollsUp() {
        let breakdown = MealBreakdown(items: [
            MealItem(
                id: "a",
                name: "Shop sandwich",
                nutrition: Macros(calories: 400, protein: 20, carbs: 40, fat: 15),
                source: .reference
            ),
            MealItem(id: "b", name: "Crisps", components: [
                component("b1", "Crisps", 25, "g", 130, source: .reference)
            ])
        ])

        #expect(calculator.provenance(of: breakdown) == .reference)
    }

    @Test("A descriptive component has no say in how certain the total is")
    func descriptiveComponentDoesNotDowngrade() {
        let breakdown = MealBreakdown(items: [
            MealItem(id: "a", name: "Salad", components: [
                component("a1", "Leaves", 100, "g", 20, source: .reference),
                // No nutrition, and no source either — must not drag the roll-up down.
                MealComponent(id: "a2", name: "Dressing, a little")
            ])
        ])

        #expect(calculator.provenance(of: breakdown) == .reference)
    }

    @Test("A breakdown with nothing in it is an estimate, not a claim")
    func emptyBreakdownIsEstimated() {
        #expect(calculator.provenance(of: MealBreakdown(items: [])) == .estimated)
    }
}
