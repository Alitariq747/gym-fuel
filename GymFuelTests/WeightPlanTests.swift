//
//  WeightPlanTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("WeightPlan")
struct WeightPlanTests {
    private let utc = TimeZone(identifier: "UTC")!
    private let week: TimeInterval = 7 * 86_400

    /// Midday UTC on the day `key` names — where a plan's line starts.
    private func day(_ key: String) throws -> Date {
        try #require(DateKey.date(from: key, timeZone: utc))
    }

    /// A profile whose plan started at 85 kg on 1 September 2026, with no
    /// maintenance estimate saved, so the line runs at the plain pace.
    private func profile(
        goal: GoalType?,
        goalWeightKg: Double? = nil,
        planStartedOn: String? = "2026-09-01",
        planStartWeightKg: Double? = 85
    ) -> UserProfile {
        var profile = UserProfile(name: "", isOnboardingComplete: true, gender: .male)
        profile.goalType = goal
        profile.goalWeightKg = goalWeightKg
        profile.planStartedOn = planStartedOn
        profile.planStartWeightKg = planStartWeightKg
        return profile
    }

    /// Losing from 85 kg toward 80.
    private func losing() throws -> WeightPlan {
        try #require(WeightPlan(profile: profile(goal: .cut, goalWeightKg: 80), timeZone: utc))
    }

    /// Gaining from 70 kg toward 75.
    private func gaining() throws -> WeightPlan {
        try #require(WeightPlan(
            profile: profile(goal: .leanBulk, goalWeightKg: 75, planStartWeightKg: 70),
            timeZone: utc
        ))
    }

    // MARK: - Pace

    @Test("The line moves at the goal's pace on the start weight")
    func paceOnStartWeight() {
        let losing = WeightPlan.weeklyChangeKg(goal: .cut, startWeightKg: 85, maintenanceCalories: nil, gender: .male)
        let gaining = WeightPlan.weeklyChangeKg(goal: .leanBulk, startWeightKg: 70, maintenanceCalories: nil, gender: .male)
        let maintaining = WeightPlan.weeklyChangeKg(goal: .maintain, startWeightKg: 70, maintenanceCalories: 2_300, gender: .male)

        #expect(abs(losing - -0.425) < 1e-9)
        #expect(abs(gaining - 0.175) < 1e-9)
        #expect(maintaining == 0)
    }

    @Test("A loss with room above the floor keeps the full pace")
    func roomyLossKeepsPace() {
        let change = WeightPlan.weeklyChangeKg(goal: .cut, startWeightKg: 85, maintenanceCalories: 2_470, gender: .male)

        #expect(abs(change - -0.425) < 1e-9)
    }

    /// The 4b case: 45 kg, 150 cm, 60, Mostly sitting. Maintenance is about 1,250
    /// and the target sits on the 1,200 floor, so the real deficit is 50 a day —
    /// not the 248 the pace alone would draw.
    @Test("A loss is eased to what the calorie floor leaves room for")
    func floorEasesTheLoss() {
        let change = WeightPlan.weeklyChangeKg(goal: .cut, startWeightKg: 45, maintenanceCalories: 1_250, gender: .female)

        #expect(abs(change - -(50.0 * 7 / 7_700)) < 1e-9)
    }

    @Test("No room above the floor gives a flat line")
    func noRoomIsFlat() {
        let change = WeightPlan.weeklyChangeKg(goal: .cut, startWeightKg: 45, maintenanceCalories: 1_180, gender: .female)

        #expect(change == 0)
    }

    @Test("Gaining is never eased by the floor")
    func gainIgnoresFloor() {
        let change = WeightPlan.weeklyChangeKg(goal: .leanBulk, startWeightKg: 50, maintenanceCalories: 1_400, gender: .male)

        #expect(abs(change - 0.125) < 1e-9)
    }

    // MARK: - From the profile

    @Test("A plan reads the saved start, goal weight and maintenance")
    func readsTheProfile() throws {
        var saved = profile(goal: .cut, goalWeightKg: 80)
        saved.maintenanceCalories = 2_470
        let start = try day("2026-09-01")

        let plan = try #require(WeightPlan(profile: saved, timeZone: utc))

        #expect(plan.goal == .cut)
        #expect(plan.startDate == start)
        #expect(plan.startWeightKg == 85)
        #expect(plan.goalWeightKg == 80)
        #expect(abs(plan.weeklyChangeKg - -0.425) < 1e-9)
    }

    @Test("Maintain has no goal weight and a flat line")
    func maintainIsFlat() throws {
        // A goal weight left over from an earlier goal must not reach the line.
        let plan = try #require(WeightPlan(profile: profile(goal: .maintain, goalWeightKg: 80), timeZone: utc))

        #expect(plan.goalWeightKg == nil)
        #expect(plan.weeklyChangeKg == 0)
        #expect(plan.weightKg(on: plan.startDate.addingTimeInterval(10 * week)) == 85)
        #expect(plan.goalDate == nil)
    }

    @Test("No goal falls back to the calculator's default, Maintain")
    func missingGoalMaintains() throws {
        let plan = try #require(WeightPlan(profile: profile(goal: nil), timeZone: utc))

        #expect(plan.goal == .maintain)
    }

    @Test("No plan without a start, a start weight, or a goal weight to head for")
    func missingFieldsGiveNoPlan() {
        #expect(WeightPlan(profile: profile(goal: .cut, goalWeightKg: 80, planStartedOn: nil), timeZone: utc) == nil)
        #expect(WeightPlan(profile: profile(goal: .cut, goalWeightKg: 80, planStartedOn: "1 Sep"), timeZone: utc) == nil)
        #expect(WeightPlan(profile: profile(goal: .cut, goalWeightKg: 80, planStartWeightKg: nil), timeZone: utc) == nil)
        #expect(WeightPlan(profile: profile(goal: .cut), timeZone: utc) == nil)
        #expect(WeightPlan(profile: profile(goal: .leanBulk), timeZone: utc) == nil)
    }

    // MARK: - The line

    @Test("Nothing is drawn before the plan started")
    func nothingBeforeStart() throws {
        let plan = try losing()

        #expect(plan.weightKg(on: plan.startDate.addingTimeInterval(-86_400)) == nil)
        #expect(plan.weightKg(on: plan.startDate) == 85)
    }

    @Test("A losing line falls at the weekly pace and holds at the goal")
    func losingLine() throws {
        let plan = try losing()
        let fourWeeks = try #require(plan.weightKg(on: plan.startDate.addingTimeInterval(4 * week)))

        #expect(abs(fourWeeks - 83.3) < 1e-9)
        #expect(plan.weightKg(on: plan.startDate.addingTimeInterval(52 * week)) == 80)
    }

    @Test("A gaining line rises at the weekly pace and holds at the goal")
    func gainingLine() throws {
        let plan = try gaining()
        let fourWeeks = try #require(plan.weightKg(on: plan.startDate.addingTimeInterval(4 * week)))

        #expect(abs(fourWeeks - 70.7) < 1e-9)
        #expect(plan.weightKg(on: plan.startDate.addingTimeInterval(52 * week)) == 75)
    }

    /// Recalculate after reaching the goal restarts the plan below it. The line
    /// must stay put rather than jump up to the goal.
    @Test("A start already past the goal stays flat")
    func startPastGoalIsFlat() throws {
        let plan = try #require(WeightPlan(
            profile: profile(goal: .cut, goalWeightKg: 80, planStartWeightKg: 79),
            timeZone: utc
        ))

        #expect(plan.weightKg(on: plan.startDate.addingTimeInterval(8 * week)) == 79)
        #expect(plan.goalDate == nil)
    }

    @Test("The goal date is when the line reaches the goal")
    func goalDate() throws {
        let plan = try losing()
        let goalDate = try #require(plan.goalDate)
        let weeks = goalDate.timeIntervalSince(plan.startDate) / week

        #expect(abs(weeks - 5 / 0.425) < 1e-9)
    }

    // MARK: - Drawing

    @Test("Points start at the plan start, turn at the goal and end with the range")
    func pointsTurnAtGoal() throws {
        let plan = try losing()
        let rangeStart = plan.startDate.addingTimeInterval(-30 * 86_400)
        let rangeEnd = plan.startDate.addingTimeInterval(20 * week)
        let goalDate = try #require(plan.goalDate)

        let points = plan.points(from: rangeStart, through: rangeEnd)

        #expect(points.map(\.date) == [plan.startDate, goalDate, rangeEnd])
        #expect(zip(points.map(\.weightKg), [85.0, 80, 80]).allSatisfy { abs($0 - $1) < 1e-9 })
    }

    @Test("A range that ends before the goal has no turn")
    func pointsWithoutTurn() throws {
        let plan = try losing()
        let rangeEnd = plan.startDate.addingTimeInterval(4 * week)

        #expect(plan.points(from: plan.startDate, through: rangeEnd).map(\.date) == [plan.startDate, rangeEnd])
    }

    @Test("A range starting after the plan start enters mid-line")
    func pointsEnterMidLine() throws {
        let plan = try losing()
        let rangeStart = plan.startDate.addingTimeInterval(2 * week)

        let first = try #require(plan.points(from: rangeStart, through: rangeStart.addingTimeInterval(week)).first)

        #expect(first.date == rangeStart)
        #expect(abs(first.weightKg - 84.15) < 1e-9)
    }

    @Test("A range that ends before the plan started draws nothing")
    func pointsBeforeStart() throws {
        let plan = try losing()

        let points = plan.points(
            from: plan.startDate.addingTimeInterval(-10 * 86_400),
            through: plan.startDate.addingTimeInterval(-86_400)
        )

        #expect(points.isEmpty)
    }

    // MARK: - Reaching the goal

    @Test("Losing reaches the goal at or below it")
    func reachedWhenLosing() throws {
        let plan = try losing()

        #expect(!plan.isGoalReached(trendKg: 80.4))
        #expect(plan.isGoalReached(trendKg: 80))
        #expect(plan.isGoalReached(trendKg: 79.6))
    }

    @Test("Gaining reaches the goal at or above it")
    func reachedWhenGaining() throws {
        let plan = try gaining()

        #expect(!plan.isGoalReached(trendKg: 74.9))
        #expect(plan.isGoalReached(trendKg: 75))
    }

    @Test("Maintain never reaches a goal")
    func maintainNeverReaches() throws {
        let plan = try #require(WeightPlan(profile: profile(goal: .maintain), timeZone: utc))

        #expect(!plan.isGoalReached(trendKg: 85))
    }
}
