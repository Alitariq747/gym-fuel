//
//  CheckInTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// The record a check-in answer saves, and what it writes onto the phase.
@Suite("CheckIn")
struct CheckInTests {
    private let utc = TimeZone(identifier: "UTC")!
    private let calculator = MacroTargetCalculator()

    private var profile: UserProfile {
        UserProfile(
            id: "test",
            name: "",
            heightCm: 180,
            age: 30,
            weightKg: 80,
            goalType: .cut,
            activityLevel: .mostlySitting,
            isOnboardingComplete: true,
            gender: .male,
            goalPace: .gentle
        )
    }

    private var now: Date {
        DateKey.date(from: "2026-09-15", timeZone: utc)!
    }

    private let reading = PaceReading(
        paceKgPerWeek: -0.1,
        goalKgPerWeek: -0.4,
        trendKg: 80,
        weighInCount: 14,
        windowDays: 21,
        loggedDays: 18
    )

    private let context = CheckInContext(loggedDays: 18, averageLoggedCalories: 1_950)

    /// A step down of 100 from the formula, as the pace rule would suggest.
    private var step: PaceCheckResult {
        let bounds = calculator.calorieBounds(for: profile)!
        let newAdjustment = -100.0
        let newCalories = max(bounds.base + newAdjustment, bounds.floor).rounded()
        let currentCalories = max(bounds.base, bounds.floor).rounded()
        return .step(reading, delta: newCalories - currentCalories, newCalories: newCalories, newAdjustment: newAdjustment)
    }

    private func make(_ result: PaceCheckResult, _ response: CheckIn.Response) -> CheckIn {
        let before = calculator.targetMacros(for: profile)!
        return CheckIn.make(
            result: result,
            phaseStartDateKey: "2026-08-18",
            dueDateKey: "2026-09-15",
            response: response,
            context: context,
            targetsBefore: before,
            targetsAfter: CheckIn.suggestedTargets(for: result, profile: profile, calculator: calculator),
            now: now,
            timeZone: utc
        )
    }

    @Test func acceptedStepSavesTheRulesTarget() {
        guard case .step(_, _, let newCalories, let newAdjustment) = step else {
            Issue.record("expected a step")
            return
        }
        let checkIn = make(step, .accepted)

        #expect(checkIn.response == .accepted)
        #expect(checkIn.targetsAfter.calories == newCalories)
        #expect(checkIn.targetsAfter != checkIn.targetsBefore)

        let update = checkIn.phaseUpdate(from: step)
        #expect(update?.calorieAdjustment == newAdjustment)
        #expect(update?.decisionDateKey == "2026-09-15")
        #expect(update?.phaseKey == "2026-08-18")
    }

    @Test func rejectedStepKeepsTheTargetAndTheSuggestion() {
        let checkIn = make(step, .rejected)

        #expect(checkIn.targetsAfter == checkIn.targetsBefore)
        #expect(checkIn.suggestedDelta == -100)

        let update = checkIn.phaseUpdate(from: step)
        #expect(update?.calorieAdjustment == nil)
        #expect(update?.decisionDateKey == "2026-09-15")
    }

    @Test func notEnoughDataIsAcknowledgedWithoutAReading() {
        let result = PaceCheckResult.notEnoughData(.waiting(daysLeft: 7))
        let checkIn = make(result, .accepted)

        #expect(checkIn.response == .acknowledged)
        #expect(checkIn.decision == .notEnoughData)
        #expect(checkIn.paceKgPerWeek == nil)
        #expect(checkIn.weighInCount == nil)
        #expect(checkIn.windowDays == nil)
        #expect(checkIn.suggestedDelta == nil)
        #expect(checkIn.targetsAfter == checkIn.targetsBefore)
        #expect(checkIn.loggedDays == 18)
        #expect(checkIn.phaseUpdate(from: result) == nil)
    }

    @Test func completedDateKeyIsTheDayAnswered() {
        #expect(make(.onPace(reading), .acknowledged).completedDateKey == "2026-09-15")
    }
}
