//
//  PaceCheckCalculatorTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// The weekly pace rule, `build-order.md` Step 4 "The pace check".
///
/// Days are offsets from 1 September 2026 in UTC, so `day(28)` is 29 September.
/// Lose fat · Gentle at 83 kg is a goal of −0.415 kg a week.
@Suite("PaceCheckCalculator")
struct PaceCheckCalculatorTests {
    private let utc = TimeZone(identifier: "UTC")!
    private let calculator = PaceCheckCalculator()

    private func day(_ offset: Int) -> String {
        let calendar = DateKey.calendar(timeZone: utc)
        let base = DateKey.date(from: "2026-09-01", timeZone: utc)!
        return DateKey.key(for: calendar.date(byAdding: .day, value: offset, to: base)!, timeZone: utc)
    }

    /// A straight line of daily weigh-ins, `startKg` on day `from`.
    private func line(
        kgPerWeek: Double,
        from: Int = 0,
        through: Int = 28,
        startKg: Double = 83,
        every step: Int = 1
    ) -> [WeighIn] {
        stride(from: from, through: through, by: step).map { offset in
            WeighIn(
                dateKey: day(offset),
                weightKg: startKg + kgPerWeek / 7 * Double(offset - from),
                loggedAt: Date(timeIntervalSince1970: 0),
                source: .manual
            )
        }
    }

    private func phase(
        goal: GoalType = .cut,
        pace: GoalPace? = .gentle,
        startDay: Int = 0,
        startWeightKg: Double = 83,
        targetWeightKg: Double? = nil,
        adjustment: Double = 0,
        decisionDay: Int? = nil
    ) -> Phase {
        Phase(
            startDateKey: day(startDay),
            goalType: goal,
            goalPace: pace,
            pacePercentPerWeek: pace?.percentPerWeek(for: goal) ?? 0,
            startWeightKg: startWeightKg,
            targetWeightKg: targetWeightKg,
            startTargets: Macros(calories: 2500, protein: 180, carbs: 250, fat: 66),
            calorieAdjustment: adjustment,
            lastStepDecisionDateKey: decisionDay.map(day),
            startedAt: Date(timeIntervalSince1970: 0)
        )
    }

    private func evaluate(
        _ weighIns: [WeighIn],
        _ phase: Phase,
        today: Int = 28,
        loggedDays: [Int]? = nil,
        base: Double = 2500,
        floor: Double = 1500
    ) -> PaceCheckResult {
        let logged = loggedDays ?? Array(0...today)
        return calculator.evaluate(
            PaceCheckCalculator.Input(
                weighIns: weighIns,
                phase: phase,
                loggedDayKeys: Set(logged.map(day)),
                todayKey: day(today),
                baseCalories: base,
                floorCalories: floor
            ),
            timeZone: utc
        )
    }

    private func isOnPace(_ result: PaceCheckResult) -> Bool {
        if case .onPace = result { return true }
        return false
    }

    private func stepDelta(_ result: PaceCheckResult) -> Double? {
        if case .step(_, let delta, _, _) = result { return delta }
        return nil
    }

    // MARK: - Measuring

    @Test("A perfect line at goal pace is on pace, measured over 21 days")
    func perfectLineIsOnPace() throws {
        let result = evaluate(line(kgPerWeek: -0.415), phase())
        #expect(isOnPace(result))

        let reading = try #require(result.reading)
        #expect(abs(reading.paceKgPerWeek - -0.415) < 1e-9)
        #expect(abs(reading.goalKgPerWeek - -0.415) < 1e-9)
        #expect(reading.windowDays == 21)
        #expect(reading.weighInCount == 21)
    }

    @Test("Sparse weigh-ins still measure the pace from real day gaps")
    func sparseWeighIns() throws {
        let result = evaluate(line(kgPerWeek: -0.415, every: 3), phase())
        #expect(isOnPace(result))
        #expect(abs(try #require(result.reading).paceKgPerWeek - -0.415) < 1e-9)
    }

    @Test("Weigh-ins before the window don't move the pace")
    func oldDataIgnored() throws {
        let old = (0...7).map { WeighIn(dateKey: day($0), weightKg: 95, loggedAt: Date(), source: .manual) }
        let result = evaluate(old + line(kgPerWeek: -0.415, from: 8), phase())
        #expect(isOnPace(result))
        #expect(try #require(result.reading).weighInCount == 21)
    }

    // MARK: - Enough data

    @Test("Day 13 waits; day 14 checks")
    func fourteenDayWait() {
        #expect(evaluate(line(kgPerWeek: -0.415, through: 13), phase(), today: 13) == .notEnoughData(.waiting(daysLeft: 1)))
        #expect(isOnPace(evaluate(line(kgPerWeek: -0.415, through: 14), phase(), today: 14)))
    }

    @Test("A phase started a week ago is not enough")
    func oneWeekIsNotEnough() {
        #expect(evaluate(line(kgPerWeek: -0.1), phase(startDay: 21)) == .notEnoughData(.waiting(daysLeft: 7)))
    }

    @Test("Five weigh-ins are too few")
    func fiveWeighIns() {
        let weighIns = line(kgPerWeek: -0.415).filter { [8, 12, 16, 20, 24].map(day).contains($0.dateKey) }
        #expect(evaluate(weighIns, phase()) == .notEnoughData(.tooFewWeighIns(count: 5)))
    }

    @Test("Readings bunched into nine days can't make a slope")
    func spanTooShort() {
        #expect(evaluate(line(kgPerWeek: -0.415, from: 19), phase()) == .notEnoughData(.spanTooShort(days: 9)))
    }

    @Test("Accepting or rejecting starts the wait again")
    func waitsAfterDecision() {
        #expect(evaluate(line(kgPerWeek: -0.1), phase(decisionDay: 20)) == .notEnoughData(.waiting(daysLeft: 6)))
    }

    // MARK: - Which way

    @Test("Too slow on a cut steps down; too fast steps up")
    func cutDirections() {
        let slow = evaluate(line(kgPerWeek: -0.1), phase())
        #expect(slow == .step(slow.reading!, delta: -100, newCalories: 2400, newAdjustment: -100))

        let fast = evaluate(line(kgPerWeek: -0.8), phase())
        #expect(fast == .step(fast.reading!, delta: 100, newCalories: 2600, newAdjustment: 100))
    }

    @Test("Gaining on a cut is too slow, not too fast")
    func wrongWayOnCut() {
        #expect(stepDelta(evaluate(line(kgPerWeek: 0.2), phase())) == -100)
    }

    @Test("Too slow on a gain steps up; too fast steps down")
    func gainDirections() {
        let gain = phase(goal: .leanBulk, pace: .slow, startWeightKg: 80)  // +0.2 kg a week
        #expect(stepDelta(evaluate(line(kgPerWeek: 0, startKg: 80), gain)) == 100)
        #expect(stepDelta(evaluate(line(kgPerWeek: 0.5, startKg: 80), gain)) == -100)
    }

    @Test("Exactly half and one-and-a-half times goal pace count as on pace")
    func toleranceEdges() {
        #expect(isOnPace(evaluate(line(kgPerWeek: -0.2075), phase())))
        #expect(isOnPace(evaluate(line(kgPerWeek: -0.6225), phase())))
        #expect(stepDelta(evaluate(line(kgPerWeek: -0.2), phase())) == -100)
        #expect(stepDelta(evaluate(line(kgPerWeek: -0.65), phase())) == 100)
    }

    @Test("Steps carry on from an existing adjustment")
    func stepsFromExistingAdjustment() {
        let result = evaluate(line(kgPerWeek: -0.1), phase(adjustment: -100))
        #expect(result == .step(result.reading!, delta: -100, newCalories: 2300, newAdjustment: -200))
    }

    // MARK: - Maintain

    @Test("Maintain inside ±0.5 kg of the start weight doesn't step")
    func maintainInBand() {
        let maintain = phase(goal: .maintain, pace: nil, startWeightKg: 80)
        guard case .inBand = evaluate(line(kgPerWeek: 0, startKg: 80.4), maintain) else {
            Issue.record("Expected inBand")
            return
        }
    }

    @Test("Maintain outside the band steps back toward it")
    func maintainOutsideBand() {
        let maintain = phase(goal: .maintain, pace: nil, startWeightKg: 80)
        #expect(stepDelta(evaluate(line(kgPerWeek: 0, startKg: 81), maintain)) == -100)
        #expect(stepDelta(evaluate(line(kgPerWeek: 0, startKg: 79), maintain)) == 100)
    }

    @Test("Maintain doesn't step when the trend is already heading back")
    func maintainHeadingBack() {
        let maintain = phase(goal: .maintain, pace: nil, startWeightKg: 80)
        let result = evaluate(line(kgPerWeek: -0.5, startKg: 83), maintain)
        #expect((result.reading?.trendKg ?? 0) > 80.5)
        guard case .inBand = result else {
            Issue.record("Expected inBand, got \(result)")
            return
        }
    }

    // MARK: - Guards

    @Test("Food logged on fewer than 5 days in 7 keeps the target")
    func loggingGap() {
        // Window is days 8–28: 21 days needs 15 logged.
        let fourteen = Array(8...21)
        guard case .loggingGap(let reading) = evaluate(line(kgPerWeek: -0.1), phase(), loggedDays: fourteen) else {
            Issue.record("Expected loggingGap")
            return
        }
        #expect(reading.loggedDays == 14)
        #expect(stepDelta(evaluate(line(kgPerWeek: -0.1), phase(), loggedDays: Array(8...22))) == -100)
    }

    @Test("A step down stops at the floor")
    func floorClamp() {
        let result = evaluate(line(kgPerWeek: -0.1), phase(), base: 1550, floor: 1500)
        #expect(result == .step(result.reading!, delta: -50, newCalories: 1500, newAdjustment: -50))
    }

    @Test("A target already at the floor can't step down")
    func atFloor() {
        guard case .atFloor = evaluate(line(kgPerWeek: -0.1), phase(), base: 1400, floor: 1500) else {
            Issue.record("Expected atFloor")
            return
        }
    }

    @Test("A step up from a floored target actually moves it")
    func stepUpFromFloor() {
        let result = evaluate(line(kgPerWeek: -0.8), phase(), base: 1400, floor: 1500)
        #expect(result == .step(result.reading!, delta: 100, newCalories: 1600, newAdjustment: 200))
    }

    // MARK: - Target weight

    @Test("A cut whose trend reaches the target offers Maintain instead of a step")
    func targetReachedOnCut() {
        guard case .targetReached = evaluate(line(kgPerWeek: -0.1, startKg: 82.1), phase(targetWeightKg: 82)) else {
            Issue.record("Expected targetReached")
            return
        }
        // Not yet reached: the normal rule applies.
        #expect(stepDelta(evaluate(line(kgPerWeek: -0.1), phase(targetWeightKg: 75))) == -100)
    }

    @Test("A gain whose trend reaches the target offers Maintain")
    func targetReachedOnGain() {
        let gain = phase(goal: .leanBulk, pace: .slow, startWeightKg: 80, targetWeightKg: 80.3)
        guard case .targetReached = evaluate(line(kgPerWeek: 0.2, startKg: 80), gain) else {
            Issue.record("Expected targetReached")
            return
        }
    }

    // MARK: - The seeder

    #if DEBUG
    private func seeded(_ scenario: DebugDataSeeder.Scenario, phaseStartDaysAgo: Int = 27) -> PaceCheckResult {
        let now = DateKey.date(from: "2026-09-29", timeZone: utc)!
        let weighIns = DebugDataSeeder.weighIns(for: scenario, now: now, timeZone: utc)
        let start = weighIns[weighIns.count - 1 - phaseStartDaysAgo]
        let phase = Phase(
            startDateKey: start.dateKey,
            goalType: DebugDataSeeder.Seed.goal,
            goalPace: DebugDataSeeder.Seed.pace,
            pacePercentPerWeek: DebugDataSeeder.Seed.pace.percentPerWeek(for: DebugDataSeeder.Seed.goal),
            startWeightKg: start.weightKg,
            targetWeightKg: nil,
            startTargets: Macros(calories: 2500, protein: 180, carbs: 250, fat: 66),
            calorieAdjustment: 0,
            lastStepDecisionDateKey: nil,
            startedAt: now
        )
        return calculator.evaluate(
            PaceCheckCalculator.Input(
                weighIns: weighIns,
                phase: phase,
                loggedDayKeys: Set(weighIns.map(\.dateKey)),
                todayKey: weighIns.last!.dateKey,
                baseCalories: 2500,
                floorCalories: 1500
            ),
            timeZone: utc
        )
    }

    @Test("The three seeded scenarios answer down, no change, up")
    func seederScenarios() {
        #expect(stepDelta(seeded(.slowerThanGoal)) == -100)
        #expect(isOnPace(seeded(.onGoal)))
        #expect(stepDelta(seeded(.fasterThanGoal)) == 100)
    }

    @Test("The seeded phase-a-week-ago scenario is not enough data")
    func seederWeekOld() {
        #expect(seeded(.slowerThanGoal, phaseStartDaysAgo: 7) == .notEnoughData(.waiting(daysLeft: 7)))
    }
    #endif
}
