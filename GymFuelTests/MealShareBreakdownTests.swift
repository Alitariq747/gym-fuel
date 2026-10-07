//
//  MealShareBreakdownTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// The share card lists a few lines of any meal, and those lines must still add
/// up to the total printed above them.
@Suite("The share card's breakdown")
struct MealShareBreakdownTests {
    private let calculator = MealBreakdownCalculator()

    private func item(_ id: String, _ calories: Double, adjustedTo adjusted: Double? = nil) -> MealItem {
        MealItem(
            id: id,
            name: id,
            amount: MealAmount(quantity: 1, unit: "portion", adjustedQuantity: adjusted),
            nutrition: Macros(calories: calories, protein: 1, carbs: 2, fat: 3)
        )
    }

    private func names(_ share: MealShareBreakdown?) -> [String] {
        share?.rows.map(\.name) ?? []
    }

    @Test("Four items or fewer are all listed, in the meal's order")
    func shortMealListsEverything() throws {
        let share = try #require(MealShareBreakdown(MealBreakdown(items: [
            item("rice", 200), item("stew", 400), item("bread", 80), item("tea", 40)
        ])))

        #expect(names(share) == ["rice", "stew", "bread", "tea"])
        #expect(share.moreCount == 0)
        #expect(share.moreMacros == nil)
    }

    @Test("A long meal keeps its three largest items, in the meal's order, and folds the rest")
    func longMealFoldsTheSmallest() throws {
        let breakdown = MealBreakdown(items: [
            item("tea", 40), item("rice", 310), item("salad", 25), item("stew", 340),
            item("lentils", 180), item("yogurt", 45), item("bread", 120)
        ])
        let share = try #require(MealShareBreakdown(breakdown))

        #expect(names(share) == ["rice", "stew", "lentils"])
        #expect(share.moreCount == 4)
        #expect(share.moreMacros?.calories == 230)
    }

    @Test("The listed rows and the folded row add up to the meal total")
    func rowsAddUpToTheTotal() throws {
        let breakdown = MealBreakdown(items: [
            item("a", 90), item("b", 310), item("c", 25), item("d", 340), item("e", 180), item("f", 45)
        ])
        let share = try #require(MealShareBreakdown(breakdown))
        let listed = share.rows.compactMap(\.macros).reduce(.zero, +)

        #expect(listed + (share.moreMacros ?? .zero) == calculator.total(of: breakdown))
    }

    @Test("Ties keep the meal's order")
    func tiesKeepMealOrder() throws {
        let share = try #require(MealShareBreakdown(MealBreakdown(items: [
            item("first", 100), item("second", 100), item("third", 100), item("fourth", 100), item("fifth", 100)
        ])))

        #expect(names(share) == ["first", "second", "third"])
        #expect(share.moreCount == 2)
    }

    @Test("A removed item is left out and does not count towards the four")
    func removedItemIsLeftOut() throws {
        let share = try #require(MealShareBreakdown(MealBreakdown(items: [
            item("rice", 200), item("stew", 400), item("oil", 120, adjustedTo: 0), item("bread", 80), item("tea", 40)
        ])))

        #expect(names(share) == ["rice", "stew", "bread", "tea"])
        #expect(share.moreCount == 0)
    }

    @Test("A meal whose every item was removed has nothing to list")
    func everythingRemovedListsNothing() {
        #expect(MealShareBreakdown(MealBreakdown(items: [item("tea", 40, adjustedTo: 0)])) == nil)
    }

    @Test("A row carries what the item contributes after a correction")
    func correctedAmountScales() throws {
        let share = try #require(MealShareBreakdown(MealBreakdown(items: [item("rice", 200, adjustedTo: 1.5)])))

        #expect(share.rows.first?.macros?.calories == 300)
    }

    @Test("An item priced by its parts lists their sum, and the parts are not listed")
    func compositeItemListsItsSum() throws {
        let share = try #require(MealShareBreakdown(MealFixtures.sampleBreakdown))

        #expect(names(share) == ["Chicken sandwich", "Salted crisps"])
        #expect(share.rows.first?.macros?.calories == 477)
    }

    @Test("Folded items with no numbers fold to a count alone")
    func descriptiveFoldHasNoNumber() throws {
        let descriptive = (1...2).map { MealItem(id: "note\($0)", name: "note\($0)") }
        let share = try #require(MealShareBreakdown(MealBreakdown(items: [
            item("a", 300), item("b", 200), item("c", 100)
        ] + descriptive)))

        #expect(share.moreCount == 2)
        #expect(share.moreMacros == nil)
    }
}
