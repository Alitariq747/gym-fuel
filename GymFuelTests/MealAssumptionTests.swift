//
//  MealAssumptionTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// The timeline gets one line, so which assumption it names matters. Ordered by
/// how much number the assumption moves — `build-order.md` Step 5, "surface the
/// most consequential assumption".
@Suite("The timeline's assumption line")
struct MealAssumptionTests {
    private let calculator = MealBreakdownCalculator()

    private func component(_ id: String, _ calories: Double, _ assumption: String?) -> MealComponent {
        MealComponent(
            id: id,
            name: id,
            amount: MealAmount(quantity: 1, unit: "portion"),
            nutrition: Macros(calories: calories, protein: 0, carbs: 0, fat: 0),
            assumption: assumption
        )
    }

    private func feedback(
        _ breakdown: MealBreakdown?,
        mealAssumptions: [String] = []
    ) -> LogEntryFeedback {
        LogEntryFeedback(
            explanation: "x",
            assumptions: mealAssumptions,
            macros: Macros(calories: 100, protein: 0, carbs: 0, fat: 0),
            breakdown: breakdown
        )
    }

    // MARK: - Which one leads

    @Test("The assumption on the part that moves the number most comes first")
    func largestContributionLeads() {
        let breakdown = MealBreakdown(items: [
            MealItem(id: "i", name: "Meal", components: [
                component("small", 40, "Skimmed milk"),
                component("large", 300, "Full-fat mayonnaise"),
                component("middle", 120, "Wholemeal bread")
            ])
        ])

        #expect(calculator.assumptions(of: feedback(breakdown)) == [
            "Full-fat mayonnaise", "Wholemeal bread", "Skimmed milk"
        ])
    }

    @Test("A correction can change which assumption leads")
    func correctionCanReorder() {
        var breakdown = MealBreakdown(items: [
            MealItem(id: "i", name: "Meal", components: [
                component("a", 300, "Full-fat mayonnaise"),
                component("b", 200, "Wholemeal bread")
            ])
        ])
        #expect(calculator.assumptions(of: feedback(breakdown)).first == "Full-fat mayonnaise")

        // Halving the mayonnaise drops it to 150, below the bread.
        breakdown.items[0].components[0].amount?.adjustedQuantity = 0.5

        #expect(calculator.assumptions(of: feedback(breakdown)).first == "Wholemeal bread")
    }

    @Test("Equal contributions keep the order the meal was written in")
    func tiesKeepDocumentOrder() {
        let breakdown = MealBreakdown(items: [
            MealItem(id: "i", name: "Meal", components: [
                component("first", 100, "Written first"),
                component("second", 100, "Written second")
            ])
        ])

        #expect(calculator.assumptions(of: feedback(breakdown)) == ["Written first", "Written second"])
    }

    @Test("An assumption on a descriptive part still surfaces, ranked last")
    func descriptivePartStillCounts() {
        let breakdown = MealBreakdown(items: [
            MealItem(id: "i", name: "Meal", components: [
                MealComponent(id: "salad", name: "Dressing", assumption: "A little dressing"),
                component("chicken", 300, "Thigh, not breast")
            ])
        ])

        #expect(calculator.assumptions(of: feedback(breakdown)) == ["Thigh, not breast", "A little dressing"])
    }

    // MARK: - Both sources

    @Test("Meal-wide assumptions follow the breakdown's own")
    func mealAssumptionsComeAfter() {
        let breakdown = MealBreakdown(items: [
            MealItem(id: "i", name: "Meal", components: [component("a", 300, "Full-fat mayonnaise")])
        ])

        #expect(calculator.assumptions(of: feedback(breakdown, mealAssumptions: ["A 25 g packet"]))
            == ["Full-fat mayonnaise", "A 25 g packet"])
    }

    @Test("With no breakdown, the meal's own assumptions are all there is")
    func fallsBackToMealAssumptions() {
        #expect(calculator.assumptions(of: feedback(nil, mealAssumptions: ["Two slices", "No butter"]))
            == ["Two slices", "No butter"])
    }

    @Test("The same assumption said twice is counted once")
    func duplicatesAreCollapsed() {
        let breakdown = MealBreakdown(items: [
            MealItem(id: "i", name: "Meal", components: [component("a", 300, "Full-fat mayonnaise")])
        ])

        #expect(calculator.assumptions(of: feedback(breakdown, mealAssumptions: ["Full-fat mayonnaise"]))
            == ["Full-fat mayonnaise"])
    }

    @Test("Blank assumptions are not assumptions")
    func blanksAreDropped() {
        let breakdown = MealBreakdown(items: [
            MealItem(id: "i", name: "Meal", components: [component("a", 300, "   ")])
        ])

        #expect(calculator.assumptions(of: feedback(breakdown, mealAssumptions: [""])).isEmpty)
    }

    @Test("A breakdown from a later contract contributes nothing")
    func unsupportedVersionIsIgnored() {
        let breakdown = MealBreakdown(version: 9, items: [
            MealItem(id: "i", name: "Meal", components: [component("a", 300, "Full-fat mayonnaise")])
        ])

        #expect(calculator.assumptions(of: feedback(breakdown, mealAssumptions: ["A 25 g packet"]))
            == ["A 25 g packet"])
    }

    @Test("A meal with no feedback has no assumptions")
    func noFeedbackNoAssumptions() {
        #expect(calculator.assumptions(of: nil).isEmpty)
    }

    /// Falls out of §6 rather than being special-cased: an override clears the
    /// breakdown and the meal's own list, so both sources are gone.
    @Test("A meal whose total the user typed has no assumption line")
    func supersededMealHasNone() {
        let analysed = feedback(MealFixtures.sampleBreakdown, mealAssumptions: ["A 25 g packet"])
        #expect(!calculator.assumptions(of: analysed).isEmpty)

        let superseded = MealBreakdownCalculator.superseding(
            analysed,
            withUserTotal: Macros(calories: 700, protein: 40, carbs: 55, fat: 30)
        )

        #expect(calculator.assumptions(of: superseded).isEmpty)
        #expect(MealCopy.assumptionLine(count: 0, lead: nil) == nil)
    }

    // MARK: - The line itself

    @Test("A single assumption stands alone, with no count in front of it")
    func oneAssumptionIsBare() {
        #expect(MealCopy.assumptionLine(count: 1, lead: "Full-fat, not light") == "Full-fat, not light")
    }

    @Test("More than one is counted, and the lead is still named")
    func manyAssumptionsAreCounted() {
        #expect(MealCopy.assumptionLine(count: 3, lead: "Full-fat, not light")
            == "3 assumptions · Full-fat, not light")
    }

    @Test("A count with nothing to name is not a line")
    func countWithoutLeadIsNothing() {
        #expect(MealCopy.assumptionLine(count: 4, lead: nil) == nil)
        #expect(MealCopy.assumptionLine(count: 4, lead: "") == nil)
    }

    @Test("The fixture meal names the mayonnaise, which is its largest assumption")
    func fixtureNamesTheMayonnaise() throws {
        let all = calculator.assumptions(of: LogEntryFeedback(
            explanation: "x",
            assumptions: ["A 25 g packet of crisps"],
            breakdown: MealFixtures.sampleBreakdown
        ))
        let line = try #require(MealCopy.assumptionLine(count: all.count, lead: all.first))

        #expect(line == "2 assumptions · Full-fat, not light")
    }
}
