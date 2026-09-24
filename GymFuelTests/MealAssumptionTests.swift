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

    private func feedback(_ breakdown: MealBreakdown?) -> LogEntryFeedback {
        LogEntryFeedback(
            explanation: "x",
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

    // MARK: - The breakdown is the only source

    /// The regression behind "9 assumptions" on a meal that has four: a meal-wide
    /// list restating what the nodes already said, counted alongside them.
    @Test("A meal's count is the number of parts that assumed something")
    func countMatchesTheNodes() {
        let breakdown = MealBreakdown(items: [
            MealItem(id: "roti", name: "Roti", amount: MealAmount(quantity: 2, unit: "roti"),
                     nutrition: Macros(calories: 220, protein: 7, carbs: 36, fat: 6),
                     assumption: "Medium, plain, little added fat"),
            MealItem(id: "karahi", name: "Chicken karahi", components: [
                component("chicken", 280, "150 g is cooked weight"),
                component("oil", 180, "1.5 tbsp, the share of the pot eaten"),
                component("base", 60, "Tomato and onion, spices left out")
            ])
        ])

        let all = calculator.assumptions(of: feedback(breakdown))

        #expect(all.count == 4)
        #expect(MealCopy.assumptionLine(count: all.count, lead: all.first)
            == "4 assumptions · 150 g is cooked weight")
    }

    @Test("A breakdown whose parts assumed nothing says nothing")
    func silentBreakdownSaysNothing() {
        let breakdown = MealBreakdown(items: [
            MealItem(id: "i", name: "Meal", components: [component("a", 300, nil)])
        ])

        #expect(calculator.assumptions(of: feedback(breakdown)).isEmpty)
    }

    /// A totals-only meal has no node for an assumption to sit on, and a sentence
    /// that fits every such meal equally is not one the reader can correct.
    @Test("A meal with no breakdown has no assumption line")
    func noBreakdownNoAssumptions() {
        #expect(calculator.assumptions(of: feedback(nil)).isEmpty)
    }

    @Test("Two parts that assume the same thing are counted once")
    func duplicatesAreCollapsed() {
        let breakdown = MealBreakdown(items: [
            MealItem(id: "i", name: "Meal", components: [
                component("a", 300, "Cooked weight, not raw"),
                component("b", 200, "Cooked weight, not raw")
            ])
        ])

        #expect(calculator.assumptions(of: feedback(breakdown)) == ["Cooked weight, not raw"])
    }

    @Test("Blank assumptions are not assumptions")
    func blanksAreDropped() {
        let breakdown = MealBreakdown(items: [
            MealItem(id: "i", name: "Meal", components: [component("a", 300, "   ")])
        ])

        #expect(calculator.assumptions(of: feedback(breakdown)).isEmpty)
    }

    @Test("A breakdown from a later contract contributes nothing")
    func unsupportedVersionIsIgnored() {
        let breakdown = MealBreakdown(version: 9, items: [
            MealItem(id: "i", name: "Meal", components: [component("a", 300, "Full-fat mayonnaise")])
        ])

        #expect(calculator.assumptions(of: feedback(breakdown)).isEmpty)
    }

    @Test("A meal with no feedback has no assumptions")
    func noFeedbackNoAssumptions() {
        #expect(calculator.assumptions(of: nil).isEmpty)
    }

    /// Falls out of §6 rather than being special-cased: an override clears the
    /// breakdown, which is where the assumptions were.
    @Test("A meal whose total the user typed has no assumption line")
    func supersededMealHasNone() {
        let analysed = feedback(MealFixtures.sampleBreakdown)
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

    @Test("A blank node assumption is not shown at all")
    func blankNodeAssumptionIsNotShown() {
        #expect(MealCopy.assumption(nil) == nil)
        #expect(MealCopy.assumption("") == nil)
        #expect(MealCopy.assumption("   \n ") == nil)
        #expect(MealCopy.assumption("  Ghee, not oil ") == "Ghee, not oil")
    }

    @Test("A count with nothing to name is not a line")
    func countWithoutLeadIsNothing() {
        #expect(MealCopy.assumptionLine(count: 4, lead: nil) == nil)
        #expect(MealCopy.assumptionLine(count: 4, lead: "") == nil)
    }

    @Test("The fixture meal names the mayonnaise, its only assumption")
    func fixtureNamesTheMayonnaise() throws {
        let all = calculator.assumptions(of: LogEntryFeedback(
            explanation: "x",
            breakdown: MealFixtures.sampleBreakdown
        ))
        let line = try #require(MealCopy.assumptionLine(count: all.count, lead: all.first))

        #expect(line == "Full-fat, not light")
    }
}
