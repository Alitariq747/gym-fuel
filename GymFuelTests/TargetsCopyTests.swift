//
//  TargetsCopyTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// These assertions deliberately avoid whole formatted strings: both the number
/// and the month come from the device locale, so "Set at 83 kg on 19 Sep" is only
/// the English form of what `setAt` returns. What is worth pinning is the
/// rounding, the unit conversion, the nil cases, and that the estimate copy never
/// claims to measure a burn.
@Suite("TargetsCopy")
struct TargetsCopyTests {

    @Test("Set at reads back the kilogram it was given")
    func setAtInKilograms() throws {
        let line = try #require(TargetsCopy.setAt(weightKg: 83, on: "2026-09-19", unit: .kilograms))

        #expect(line.hasPrefix("Set at"))
        #expect(line.contains("83"))
        #expect(line.contains("kg"))
        #expect(line.contains("19"))
    }

    @Test("Set at converts to pounds for a pounds user")
    func setAtInPounds() throws {
        let line = try #require(TargetsCopy.setAt(weightKg: 83, on: "2026-09-19", unit: .pounds))

        // 83 kg is 182.98 lb, which rounds to 183 rather than truncating to 182.
        #expect(line.contains("183"))
        #expect(line.contains("lbs"))
    }

    @Test("Set at shows a whole weight, not the stored two decimal places")
    func setAtRoundsToWholeUnits() throws {
        let line = try #require(TargetsCopy.setAt(weightKg: 83.64, on: "2026-09-19", unit: .kilograms))

        #expect(line.contains("84"))
        #expect(!line.contains("83"))
    }

    @Test("Set at needs both a weight and a day that exists")
    func setAtNeedsBoth() {
        #expect(TargetsCopy.setAt(weightKg: nil, on: "2026-09-19", unit: .kilograms) == nil)
        #expect(TargetsCopy.setAt(weightKg: 83, on: nil, unit: .kilograms) == nil)
        #expect(TargetsCopy.setAt(weightKg: 83, on: "", unit: .kilograms) == nil)
        // `DateKey.date(from:)` rejects a day that does not exist rather than
        // rolling it forward into March, and the copy follows it.
        #expect(TargetsCopy.setAt(weightKg: 83, on: "2026-02-30", unit: .kilograms) == nil)
    }

    @Test("The maintenance estimate shows no decimals")
    func maintenanceValueDropsDecimals() {
        #expect(TargetsCopy.maintenanceValue(2_420).contains("420"))
        #expect(TargetsCopy.maintenanceValue(2_420.4) == TargetsCopy.maintenanceValue(2_420))
        #expect(TargetsCopy.maintenanceValue(2_419.6) == TargetsCopy.maintenanceValue(2_420))
    }

    /// The App Store 1.4.1 failure mode, as a test: a number that claims to
    /// measure what this person burns needs validation the app does not have.
    @Test("The estimate copy never calls it a burn")
    func estimateNeverSaysBurn() {
        let copy = [
            TargetsCopy.maintenanceLabel,
            TargetsCopy.maintenancePrefix,
            TargetsCopy.maintenanceSuffix,
        ]
        .joined(separator: " ")
        .lowercased()

        #expect(!copy.contains("burn"))
        #expect(copy.contains("about"))
    }

    // MARK: - Editing the four numbers

    @Test("One changed field is named on its own")
    func headlineForOneField() {
        #expect(TargetsCopy.changedHeadline([.carbs]) == "You changed your carbs")
    }

    @Test("Two changed fields are joined with and")
    func headlineForTwoFields() {
        #expect(TargetsCopy.changedHeadline([.protein, .fat]) == "You changed your protein and fat")
    }

    /// Built from the field order, not from the set: a `Set` has no order, so
    /// interpolating one at the call site would word the same edit differently
    /// from one run to the next.
    @Test("Three changed fields read in field order, whatever order the set is in")
    func headlineForThreeFields() {
        let expected = "You changed your protein, carbs and fat"

        #expect(TargetsCopy.changedHeadline([.protein, .carbs, .fat]) == expected)
        #expect(TargetsCopy.changedHeadline([.fat, .carbs, .protein]) == expected)
    }

    @Test("A change line names the field, both numbers and the unit")
    func changeLineReadsBeforeAndAfter() {
        let line = TargetsCopy.changeLine(TargetChange(field: .protein, before: 170, after: 157))

        #expect(line.hasPrefix("Protein"))
        #expect(line.contains("170"))
        #expect(line.contains("157"))
        #expect(line.contains("→"))
        #expect(line.contains("g"))
        #expect(!line.contains("kcal"))
    }

    @Test("The calorie line is in kcal, not grams")
    func changeLineForCalories() {
        let line = TargetsCopy.changeLine(TargetChange(field: .calories, before: 2_000, after: 2_400))

        #expect(line.hasPrefix("Calories"))
        #expect(line.contains("kcal"))
    }

    /// VoiceOver reads "→" as nothing useful, and an arrow does not mirror in a
    /// right-to-left layout.
    @Test("The spoken change line says to instead of drawing an arrow")
    func spokenChangeLineHasNoArrow() {
        let spoken = TargetsCopy.changeLineSpoken(TargetChange(field: .protein, before: 170, after: 157))

        #expect(!spoken.contains("→"))
        #expect(spoken.contains(" to "))
        #expect(spoken.contains("170"))
        #expect(spoken.contains("157"))
    }

    @Test("The floor note says which floor held")
    func floorNoteNamesTheFloor() throws {
        let atGenderFloor = try #require(TargetsCopy.floorNote(
            resolved: Macros(calories: 1_200, protein: 100, carbs: 110, fat: 40),
            requestedCalories: 900,
            gender: .female
        ))
        #expect(atGenderFloor.contains("the lowest this app will set"))

        let aboveIt = try #require(TargetsCopy.floorNote(
            resolved: Macros(calories: 1_240, protein: 162, carbs: 2, fat: 65),
            requestedCalories: 900,
            gender: .female
        ))
        #expect(aboveIt.contains("protein and fat"))
    }

    @Test("No floor note when nothing was lifted")
    func floorNoteAbsentWhenNothingLifted() {
        #expect(TargetsCopy.floorNote(
            resolved: Macros(calories: 2_000, protein: 162, carbs: 192, fat: 65),
            requestedCalories: 2_000,
            gender: .male
        ) == nil)
    }
}
