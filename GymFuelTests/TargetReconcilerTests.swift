//
//  TargetReconcilerTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("TargetReconciler")
struct TargetReconcilerTests {

    /// The targets a male, 30, 180 cm, 85 kg account losing fat and mostly sitting
    /// is given — the row at `MacroTargetCalculatorTests.losingPace`. Its basis is
    /// the BMI 25 weight for 180 cm, 81 kg.
    private let start = Macros(calories: 2_000, protein: 162, carbs: 192, fat: 65)
    private let basisKg: Double = 81

    private func macros(_ kcal: Double, _ p: Double, _ c: Double, _ f: Double) -> Macros {
        Macros(calories: kcal, protein: p, carbs: c, fat: f)
    }

    // MARK: - Which fields the user touched

    /// The one that matters. `start`'s own grams cost 2,001 kcal against its
    /// 2,000 kcal target, so anything that decided "edited" by adding the numbers
    /// up would flag an untouched sheet the moment it opened.
    @Test("Untouched targets report no edit, even though their grams miss by a kcal")
    func untouchedReportsNothing() {
        #expect((start.protein * 4) + (start.carbs * 4) + (start.fat * 9) == 2_001)
        #expect(TargetReconciler.changedFields(in: start, from: start).isEmpty)
    }

    @Test("A typed carb number is the only field reported")
    func oneChangedField() {
        var typed = start
        typed.carbs = 200
        #expect(TargetReconciler.changedFields(in: typed, from: start) == [.carbs])
    }

    @Test("Calories and a macro are both reported")
    func twoChangedFields() {
        var typed = start
        typed.calories = 2_400
        typed.protein = 170
        #expect(TargetReconciler.changedFields(in: typed, from: start) == [.calories, .protein])
    }

    @Test("Typing a value back to where it started clears the edit")
    func revertedFieldClears() {
        var typed = start
        typed.protein = 170
        typed.protein = 162
        #expect(TargetReconciler.changedFields(in: typed, from: start).isEmpty)
    }

    // MARK: - Recalculating the macros, after a calorie edit

    @Test("More calories keep the rule's protein and fat, and carbs take the rest")
    func recalculatedMacrosLosing() {
        let result = TargetReconciler.recalculatingMacros(
            calories: 2_400, basisKg: basisKg, goal: .cut, gender: .male
        )
        // 81 × 2.0 and 81 × 0.8; carbs are (2400 − 648 − 585) ÷ 4.
        #expect(result == macros(2_400, 162, 292, 65))
    }

    @Test("Maintaining drops protein to 1.6 g/kg")
    func recalculatedMacrosMaintaining() {
        let result = TargetReconciler.recalculatingMacros(
            calories: 2_400, basisKg: basisKg, goal: .maintain, gender: .male
        )
        #expect(result == macros(2_400, 130, 324, 65))
    }

    @Test("Gaining raises fat to 0.9 g/kg")
    func recalculatedMacrosGaining() {
        let result = TargetReconciler.recalculatingMacros(
            calories: 2_400, basisKg: basisKg, goal: .leanBulk, gender: .male
        )
        #expect(result == macros(2_400, 130, 306, 73))
    }

    /// Typing the number the app itself worked out gives the app's own targets
    /// back, rather than something a rounding step away from them.
    @Test("The app's own calorie number returns the app's own targets")
    func recalculatedMacrosRoundTrips() {
        let result = TargetReconciler.recalculatingMacros(
            calories: 2_000, basisKg: basisKg, goal: .cut, gender: .male
        )
        #expect(result == start)
    }

    @Test("A calorie number below the floor is lifted, and carbs take what is left")
    func recalculatedMacrosHitsFloor() {
        let result = TargetReconciler.recalculatingMacros(
            calories: 900, basisKg: basisKg, goal: .cut, gender: .female
        )
        // Protein and fat cost 1,233, which rounds up to 1,240 so carbs stay ≥ 0.
        #expect(result == macros(1_240, 162, 2, 65))
        #expect(result.calories > SafetyLimits.calorieFloor(for: .female))
    }

    // MARK: - Recalculating the calories, after a macro edit

    /// The other half of the rounding story: asked what the untouched grams cost,
    /// the answer is 2,001, not the 2,000 they were saved against.
    @Test("Untouched macros cost what they cost")
    func recalculatedCaloriesFromUntouched() {
        let result = TargetReconciler.recalculatingCalories(start, gender: .male)
        #expect(result == macros(2_001, 162, 192, 65))
    }

    @Test("More carbs raise the calories and move nothing else")
    func recalculatedCaloriesFromMoreCarbs() {
        var typed = start
        typed.carbs = 250
        #expect(TargetReconciler.recalculatingCalories(typed, gender: .male) == macros(2_233, 162, 250, 65))
    }

    @Test("Macros too cheap for the floor lift the calories, and the surplus goes to carbs")
    func recalculatedCaloriesHitsGenderFloor() {
        let typed = macros(0, 100, 20, 40)
        // 840 kcal of food against a 1,200 floor; the 360 kcal gap becomes carbs.
        #expect(TargetReconciler.recalculatingCalories(typed, gender: .female) == macros(1_200, 100, 110, 40))
    }

    @Test("Protein and fat above the gender floor set the floor themselves")
    func recalculatedCaloriesHitsProteinFatFloor() {
        let typed = macros(0, 200, 0, 100)
        #expect(TargetReconciler.recalculatingCalories(typed, gender: .male) == macros(1_700, 200, 0, 100))
    }

    // MARK: - Adjusting the macros, after a macro edit

    @Test("One free macro takes the whole difference")
    func adjustedWithOneFreeMacro() throws {
        var typed = start
        typed.protein = 180
        let result = try #require(
            TargetReconciler.adjustingMacros(typed, touched: [.protein, .fat], gender: .male)
        )
        #expect(result == macros(2_000, 180, 174, 65))
    }

    @Test("Two free macros share the difference in proportion to what they hold")
    func adjustedWithTwoFreeMacros() throws {
        var typed = start
        typed.protein = 180
        let result = try #require(
            TargetReconciler.adjustingMacros(typed, touched: [.protein], gender: .male)
        )
        #expect(result == macros(2_000, 180, 183, 61))
    }

    @Test("Nothing is free to absorb when all three macros were typed")
    func adjustedWithNoFreeMacro() {
        #expect(TargetReconciler.adjustingMacros(start, touched: [.protein, .carbs, .fat], gender: .male) == nil)
    }

    @Test("No answer exists when the typed macros already cost more than the calories")
    func adjustedWhenHeldMacrosOverspend() {
        var typed = start
        typed.protein = 300
        typed.fat = 120
        #expect(TargetReconciler.adjustingMacros(typed, touched: [.protein, .fat], gender: .male) == nil)
    }

    /// Reachable: a floor squeeze can leave carbs at 0, and the next edit still
    /// has to put its difference somewhere.
    @Test("A free macro holding nothing still absorbs")
    func adjustedWithEmptyFreeMacro() throws {
        let typed = macros(1_240, 150, 0, 60)
        let result = try #require(
            TargetReconciler.adjustingMacros(typed, touched: [.protein, .fat], gender: .female)
        )
        #expect(result == macros(1_240, 150, 25, 60))
    }

    /// Two free macros both holding nothing have no proportions to keep, so the
    /// difference splits evenly before the absorber takes the remainder.
    @Test("Two empty free macros split the difference evenly")
    func adjustedWithTwoEmptyFreeMacros() throws {
        let typed = macros(1_400, 120, 0, 0)
        let result = try #require(
            TargetReconciler.adjustingMacros(typed, touched: [.protein], gender: .female)
        )
        #expect(result == macros(1_400, 120, 115, 51))
    }

    @Test("A calorie number under the floor has no adjustment")
    func adjustedRefusesBelowTheFloor() {
        let typed = macros(1_100, 100, 100, 30)
        #expect(TargetReconciler.adjustingMacros(typed, touched: [.protein], gender: .female) == nil)
    }

    /// Adjusting holds the calorie target, which is the whole point of offering it
    /// beside *Recalculate calories*.
    @Test("Adjusting never moves the calories")
    func adjustedHoldsCalories() throws {
        for touched: Set<TargetField> in [[.protein], [.carbs], [.fat], [.protein, .fat]] {
            var typed = start
            typed.protein = 180
            typed.carbs = 200
            let result = try #require(
                TargetReconciler.adjustingMacros(typed, touched: touched, gender: .male)
            )
            #expect(result.calories == start.calories)
        }
    }

    // MARK: - The change list

    @Test("Only the lines that moved are listed, in field order")
    func changesListsMovedLines() {
        let after = macros(2_400, 162, 292, 65)
        let changes = TargetReconciler.changes(from: start, to: after)

        #expect(changes.map(\.field) == [.calories, .carbs])
        #expect(changes.first == TargetChange(field: .calories, before: 2_000, after: 2_400))
    }

    @Test("Macros cost what the Atwater factors say, whatever the calorie field holds")
    func calorieCostIgnoresTheCalorieField() {
        #expect(TargetReconciler.calorieCost(of: start) == 2_001)
        #expect(TargetReconciler.calorieCost(of: macros(99_999, 162, 192, 65)) == 2_001)
        #expect(TargetReconciler.calorieCost(of: .zero) == 0)
    }

    @Test("Nothing moved gives no lines")
    func changesOfNothing() {
        #expect(TargetReconciler.changes(from: start, to: start).isEmpty)
    }
}
