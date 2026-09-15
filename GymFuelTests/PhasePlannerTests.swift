//
//  PhasePlannerTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("PhasePlanner")
struct PhasePlannerTests {
    private struct NotStarted: Error {}

    private let planner = PhasePlanner()
    private let calculator = MacroTargetCalculator()
    private let now = Date(timeIntervalSince1970: 1_789_000_000)
    private let today = "2026-09-14"

    private func profile(
        goal: GoalType = .cut,
        pace: GoalPace? = .steady,
        weightKg: Double? = 80,
        targetWeightKg: Double? = nil,
        isOnboardingComplete: Bool = true
    ) -> UserProfile {
        UserProfile(
            id: "test",
            name: "",
            heightCm: 180,
            age: 30,
            weightKg: weightKg,
            goalType: goal,
            activityLevel: .mostlySitting,
            isOnboardingComplete: isOnboardingComplete,
            gender: .male,
            goalPace: pace,
            targetWeightKg: targetWeightKg
        )
    }

    private func phase(
        startDateKey: String = "2026-08-20",
        goal: GoalType = .cut,
        pace: GoalPace? = .steady,
        targetWeightKg: Double? = nil,
        adjustment: Double = 0,
        decisionKey: String? = nil
    ) -> Phase {
        Phase(
            startDateKey: startDateKey,
            goalType: goal,
            goalPace: pace,
            pacePercentPerWeek: pace?.percentPerWeek(for: goal) ?? 0,
            startWeightKg: 82,
            targetWeightKg: targetWeightKg,
            startTargets: Macros(calories: 2000, protein: 180, carbs: 180, fat: 64),
            calorieAdjustment: adjustment,
            lastStepDecisionDateKey: decisionKey,
            startedAt: Date(timeIntervalSince1970: 0)
        )
    }

    private func started(_ plan: PhasePlan) throws -> Phase {
        guard case .start(let phase) = plan else {
            Issue.record("Expected a new phase, got \(plan)")
            throw NotStarted()
        }
        return phase
    }

    @Test("No phase yet starts one today, with the targets it starts with")
    func noPhaseStarts() throws {
        let profile = profile()
        let new = try started(planner.plan(profile: profile, current: nil, todayKey: today, now: now))

        #expect(new.startDateKey == today)
        #expect(new.goalType == .cut)
        #expect(new.goalPace == .steady)
        #expect(new.pacePercentPerWeek == 0.75)
        #expect(new.startWeightKg == 80)
        #expect(new.calorieAdjustment == 0)
        #expect(new.lastStepDecisionDateKey == nil)
        #expect(new.startedAt == now)
        #expect(new.startTargets == calculator.targetMacros(for: profile))
    }

    @Test("An unchanged goal and pace keep the phase")
    func unchangedKeeps() {
        #expect(planner.plan(profile: profile(), current: phase(), todayKey: today, now: now) == .keep)
    }

    @Test("A pace change starts a phase today, carrying the adjustment and clearing the decision date")
    func paceChangeCarriesAdjustment() throws {
        let profile = profile(pace: .faster)
        let current = phase(pace: .steady, adjustment: -200, decisionKey: "2026-09-01")
        let new = try started(planner.plan(profile: profile, current: current, todayKey: today, now: now))

        #expect(new.startDateKey == today)
        #expect(new.goalPace == .faster)
        #expect(new.calorieAdjustment == -200)
        #expect(new.lastStepDecisionDateKey == nil)
        #expect(new.startTargets == calculator.targetMacros(for: profile, calorieAdjustment: -200))
    }

    @Test("A goal change starts a phase; Maintain has no pace and no target")
    func goalChangeStarts() throws {
        let profile = profile(goal: .maintain, pace: .faster, targetWeightKg: 72)
        let new = try started(planner.plan(profile: profile, current: phase(adjustment: 100), todayKey: today, now: now))

        #expect(new.goalType == .maintain)
        #expect(new.goalPace == nil)
        #expect(new.pacePercentPerWeek == 0)
        #expect(new.targetWeightKg == nil)
        #expect(new.calorieAdjustment == 100)
    }

    @Test("A second change on the same day keeps the day's key")
    func sameDayKeepsKey() throws {
        let current = phase(startDateKey: today, pace: .steady)
        let new = try started(planner.plan(profile: profile(pace: .gentle), current: current, todayKey: today, now: now))
        #expect(new.startDateKey == today)
    }

    @Test("A clock behind the current phase cannot move the key backwards")
    func neverEarlierThanCurrent() throws {
        let current = phase(startDateKey: "2026-09-20", pace: .steady)
        let new = try started(planner.plan(profile: profile(pace: .gentle), current: current, todayKey: today, now: now))
        #expect(new.startDateKey == "2026-09-20")
    }

    @Test("Changing only the target weight updates the phase in place")
    func targetWeightOnlyUpdates() {
        #expect(
            planner.plan(profile: profile(targetWeightKg: 72), current: phase(), todayKey: today, now: now)
                == .updateTargetWeight(72)
        )
        #expect(
            planner.plan(profile: profile(), current: phase(targetWeightKg: 72), todayKey: today, now: now)
                == .updateTargetWeight(nil)
        )
    }

    @Test("Maintain ignores a leftover pace and target")
    func maintainIgnoresLeftovers() {
        let profile = profile(goal: .maintain, pace: .faster, targetWeightKg: 72)
        let current = phase(goal: .maintain, pace: nil)
        #expect(planner.plan(profile: profile, current: current, todayKey: today, now: now) == .keep)
    }

    @Test("An unfinished profile never starts a phase")
    func incompleteProfileKeeps() {
        #expect(planner.plan(profile: profile(isOnboardingComplete: false), current: nil, todayKey: today, now: now) == .keep)
        #expect(planner.plan(profile: profile(weightKg: nil), current: nil, todayKey: today, now: now) == .keep)
    }
}
