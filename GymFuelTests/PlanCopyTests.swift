//
//  PlanCopyTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// Numbers and months come from the device locale, as in `TargetsCopyTests`, so
/// these check the pieces that matter — the amounts, the direction, the unit, what
/// an edit says — formatted the way the copy formats them, rather than whole
/// English sentences.
@Suite("PlanCopy")
struct PlanCopyTests {
    private let calculator = MacroTargetCalculator()
    private let utc = TimeZone(identifier: "UTC")!

    /// Midday UTC on the day `key` names — where a plan's line starts.
    private func day(_ key: String) throws -> Date {
        try #require(DateKey.date(from: key, timeZone: utc))
    }

    private func oneDecimal(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }

    // MARK: - Headline

    @Test("A plan heading somewhere names the goal and the month it gets there")
    func headlineWithAGoalDate() throws {
        let line = WeightPlan(goal: .cut, startDate: try day("2026-09-19"), startWeightKg: 85, goalWeightKg: 75, weeklyChangeKg: -0.425)
        let goalDate = try #require(line.goalDate)
        let text = PlanCopy.headline(for: line, unit: .kilograms)

        #expect(text.contains("85 kg"))
        #expect(text.contains("75 kg"))
        #expect(text.contains(goalDate.formatted(.dateTime.month(.wide).year())))
    }

    /// Decided 19 September: the pace is an estimate, so the date is only a month.
    @Test("The date is a month and a year, never a day")
    func headlineHasNoDay() throws {
        // 5 kg at 0.5 kg a week from 1 September lands on 10 November.
        let line = WeightPlan(goal: .cut, startDate: try day("2026-09-01"), startWeightKg: 85, goalWeightKg: 80, weeklyChangeKg: -0.5)
        let goalDate = try #require(line.goalDate)
        let text = PlanCopy.headline(for: line, unit: .kilograms)

        #expect(!text.contains(goalDate.formatted(.dateTime.day())))
    }

    @Test("Maintaining has no goal and no date")
    func headlineWhenMaintaining() throws {
        let line = WeightPlan(goal: .maintain, startDate: try day("2026-09-19"), startWeightKg: 85, goalWeightKg: nil, weeklyChangeKg: 0)
        let text = PlanCopy.headline(for: line, unit: .kilograms)

        #expect(text.hasPrefix("Staying around"))
        #expect(text.contains("85 kg"))
    }

    @Test("A line with no room to move names the goal but promises no date")
    func headlineWithoutAGoalDate() throws {
        let line = WeightPlan(goal: .cut, startDate: try day("2026-09-19"), startWeightKg: 45, goalWeightKg: 42, weeklyChangeKg: 0)
        let text = PlanCopy.headline(for: line, unit: .kilograms)

        #expect(line.goalDate == nil)
        #expect(text.contains("toward"))
        #expect(text.contains("42 kg"))
        #expect(!text.contains("around"))
    }

    @Test("A pounds user reads whole pounds")
    func headlineInPounds() throws {
        let line = WeightPlan(goal: .cut, startDate: try day("2026-09-19"), startWeightKg: 85, goalWeightKg: 75, weeklyChangeKg: -0.425)
        let text = PlanCopy.headline(for: line, unit: .pounds)

        // 85 kg is 187.4 lb and 75 kg is 165.3 lb.
        #expect(text.contains("187 lbs"))
        #expect(text.contains("165 lbs"))
    }

    // MARK: - Calories

    @Test("Losing says how much less, and how fast")
    func caloriesWhenLosing() {
        let text = PlanCopy.calories(targetKcal: 1_950, maintenanceKcal: 2_420, weeklyChangeKg: -0.425, unit: .kilograms)

        #expect(text.contains("470 less"))
        #expect(text.contains("lose about \(oneDecimal(0.4)) kg a week"))
    }

    @Test("Gaining says how much more, and how fast")
    func caloriesWhenGaining() {
        let text = PlanCopy.calories(targetKcal: 2_410, maintenanceKcal: 2_220, weeklyChangeKg: 0.175, unit: .kilograms)

        #expect(text.contains("190 more"))
        #expect(text.contains("gain about \(oneDecimal(0.2)) kg a week"))
    }

    @Test("Maintaining says the target is the estimate")
    func caloriesWhenMaintaining() {
        #expect(PlanCopy.calories(targetKcal: 2_420, maintenanceKcal: 2_420, weeklyChangeKg: 0, unit: .kilograms) == "Your target is the same.")
    }

    /// A small, older, mostly sitting body can have an estimate under the floor.
    @Test("A target the floor holds above the estimate says so, and claims no pace")
    func caloriesHeldByTheFloor() {
        let text = PlanCopy.calories(targetKcal: 1_200, maintenanceKcal: 1_150, weeklyChangeKg: 0, unit: .kilograms)

        #expect(text.contains("50 more"))
        #expect(text.contains("lowest"))
        #expect(!text.contains("week"))
    }

    @Test("A pace too small for one decimal place is not shown as zero")
    func caloriesWithATinyPace() {
        let text = PlanCopy.calories(targetKcal: 1_200, maintenanceKcal: 1_250, weeklyChangeKg: -0.045, unit: .kilograms)

        #expect(text.contains("less than \(oneDecimal(0.1)) kg a week"))
        #expect(!text.contains(oneDecimal(0)))
    }

    @Test("A pounds user reads the pace in pounds")
    func caloriesInPounds() {
        // 0.425 kg is 0.94 lb.
        let text = PlanCopy.calories(targetKcal: 1_950, maintenanceKcal: 2_420, weeklyChangeKg: -0.425, unit: .pounds)

        #expect(text.contains("about \(oneDecimal(0.9)) lbs a week"))
    }

    // MARK: - Protein and fat

    @Test("Protein and fat name the weight they were worked out from")
    func perKgNamesTheWeight() {
        #expect(PlanCopy.perKg(1.6, of: .goalWeight).hasSuffix("for each kg of your goal weight."))
        #expect(PlanCopy.perKg(1.6, of: .currentWeight).hasSuffix("for each kg of your weight."))
        #expect(PlanCopy.perKg(1.6, of: .topHealthyWeight).hasSuffix("for each kg of the top healthy weight for your height."))
        #expect(PlanCopy.perKg(0.8, of: .goalWeight).hasPrefix("\(oneDecimal(0.8)) g"))
    }

    // MARK: - One reason per target

    /// 35, 178 cm, 85 kg, mostly sitting, losing toward 75 kg: 1,950 kcal, 150 g
    /// protein and 60 g fat, against an estimate of 2,420 — the example in
    /// `build-order.md` Step 4.
    private let answers = OnboardingAnswers(
        gender: .male,
        age: 35,
        heightCm: 178,
        weightKg: 85,
        goalType: .cut,
        activityLevel: .mostlySitting,
        goalWeightKg: 75
    )

    /// What the plan screen will say for `given`, compared against the numbers
    /// the same answers work out to.
    private func planReasons(for given: OnboardingAnswers) throws -> PlanCopy.Reasons {
        let today = try day("2026-09-19")
        let profile = try #require(given.plannedProfile(id: "uid", on: today, using: calculator))
        let workedOut = try #require(calculator.targetMacros(for: profile))
        return try #require(PlanCopy.reasons(for: profile, workedOut: workedOut, unit: .kilograms, calculator: calculator))
    }

    @Test("Every worked-out number gives its working")
    func reasonsForWorkedOutNumbers() throws {
        let reasons = try planReasons(for: answers)

        #expect(reasons.calories.contains("470 less"))
        #expect(reasons.calories.contains("lose about \(oneDecimal(0.4)) kg a week"))
        #expect(reasons.protein == PlanCopy.perKg(GoalType.cut.proteinPerKg, of: .goalWeight))
        #expect(reasons.fat == PlanCopy.perKg(GoalType.cut.fatPerKg, of: .goalWeight))
        #expect(reasons.carbs == PlanCopy.carbs)
    }

    @Test("Typed calories say so, and protein and fat keep their working")
    func reasonsAfterACalorieEdit() throws {
        var edited = answers
        edited.editedTargets = MacroTargetCalculator.edited(calories: 2_100, proteinG: 150, fatG: 60, gender: .male)
        let reasons = try planReasons(for: edited)

        #expect(reasons.calories == PlanCopy.setByYou)
        #expect(reasons.protein == PlanCopy.perKg(GoalType.cut.proteinPerKg, of: .goalWeight))
        #expect(reasons.fat == PlanCopy.perKg(GoalType.cut.fatPerKg, of: .goalWeight))
        #expect(reasons.carbs == PlanCopy.carbs)
    }

    /// Carbs are the one target the plan screen used to explain unconditionally,
    /// which stopped being true the moment they could be typed.
    @Test("Typed carbs say so instead of explaining the remainder")
    func reasonsAfterACarbEdit() throws {
        var edited = answers
        edited.editedTargets = Macros(calories: 1_950, protein: 150, carbs: 180, fat: 60)
        let reasons = try planReasons(for: edited)

        #expect(reasons.carbs == PlanCopy.setByYou)
        #expect(reasons.protein == PlanCopy.perKg(GoalType.cut.proteinPerKg, of: .goalWeight))
        #expect(reasons.calories.contains("470 less"))
    }

    @Test("Typed protein says so, and the calories keep their working")
    func reasonsAfterAProteinEdit() throws {
        var edited = answers
        edited.editedTargets = MacroTargetCalculator.edited(calories: 1_950, proteinG: 170, fatG: 60, gender: .male)
        let reasons = try planReasons(for: edited)

        #expect(reasons.protein == PlanCopy.setByYou)
        #expect(reasons.calories.contains("470 less"))
    }

    @Test("Maintaining above the BMI 25 weight names the top healthy weight")
    func reasonsWhenMaintainingAboveTheCap() throws {
        var maintaining = answers
        maintaining.goalType = .maintain
        let reasons = try planReasons(for: maintaining)

        // 85 kg at 178 cm is over the 79.2 kg BMI 25 weight.
        #expect(reasons.calories == "Your target is the same.")
        #expect(reasons.protein == PlanCopy.perKg(GoalType.maintain.proteinPerKg, of: .topHealthyWeight))
    }

    /// The App Store 1.4.1 failure mode, as in `TargetsCopyTests`.
    @Test("Nothing the plan screen says calls anything a burn")
    func neverSaysBurn() throws {
        let reasons = try planReasons(for: answers)
        let copy = [
            reasons.calories,
            reasons.protein,
            reasons.carbs,
            reasons.fat,
            PlanCopy.setByYou,
            PlanCopy.calories(targetKcal: 1_200, maintenanceKcal: 1_150, weeklyChangeKg: 0, unit: .kilograms),
        ]
        .joined(separator: " ")
        .lowercased()

        #expect(!copy.contains("burn"))
    }
}
