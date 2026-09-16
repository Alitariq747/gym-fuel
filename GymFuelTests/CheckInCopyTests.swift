//
//  CheckInCopyTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// The check-in's one sentence. Lose fat · Gentle at 80 kg is a goal of −0.4 kg
/// a week.
@Suite("CheckInCopy")
struct CheckInCopyTests {
    private let english = Locale(identifier: "en_US")

    private func copy(_ unit: BodyWeightUnit = .kilograms) -> CheckInCopy {
        CheckInCopy(unit: unit, locale: english)
    }

    private func phase(goal: GoalType = .cut, startWeightKg: Double = 80) -> Phase {
        Phase(
            startDateKey: "2026-09-01",
            goalType: goal,
            goalPace: goal == .maintain ? nil : .gentle,
            pacePercentPerWeek: goal == .maintain ? 0 : 0.5,
            startWeightKg: startWeightKg,
            targetWeightKg: nil,
            startTargets: .zero,
            calorieAdjustment: 0,
            lastStepDecisionDateKey: nil,
            startedAt: Date(timeIntervalSince1970: 0)
        )
    }

    private func reading(pace: Double, goal: Double = -0.4, trendKg: Double = 80, windowDays: Int = 14) -> PaceReading {
        PaceReading(
            paceKgPerWeek: pace,
            goalKgPerWeek: goal,
            trendKg: trendKg,
            weighInCount: 12,
            windowDays: windowDays,
            loggedDays: 12
        )
    }

    @Test func acceptedStepMatchesTheBuildOrderExample() {
        let result = PaceCheckResult.step(reading(pace: -0.1), delta: -100, newCalories: 1_900, newAdjustment: -100)
        #expect(
            copy().sentence(for: result, phase: phase(), currentCalories: 2_000, accepted: true)
                == "You aimed to lose about 0.4 kg a week and lost about 0.1 kg a week over the last two weeks, so your target is now 1,900 kcal, down from 2,000."
        )
    }

    @Test func stepIsOnlySuggestedBeforeAnAnswer() {
        let result = PaceCheckResult.step(reading(pace: -0.1), delta: -100, newCalories: 1_900, newAdjustment: -100)
        let sentence = copy().sentence(for: result, phase: phase(), currentCalories: 2_000)
        #expect(sentence.contains("so we suggest 1,900 kcal, down from 2,000."))
        #expect(!sentence.contains("is now"))
    }

    @Test func fasterThanChosenSaysSo() {
        let result = PaceCheckResult.step(reading(pace: -0.8, windowDays: 21), delta: 100, newCalories: 2_100, newAdjustment: 100)
        #expect(
            copy().sentence(for: result, phase: phase(), currentCalories: 2_000)
                == "You aimed to lose about 0.4 kg a week and lost about 0.8 kg a week over the last three weeks, so we suggest 2,100 kcal, up from 2,000, to bring you back to the pace you picked."
        )
    }

    @Test func poundsUseThePreferredUnit() {
        let result = PaceCheckResult.onPace(reading(pace: -0.1))
        let sentence = copy(.pounds).sentence(for: result, phase: phase(), currentCalories: 2_000)
        #expect(sentence.contains("about 0.9 lbs a week"))
        #expect(sentence.contains("lost about 0.2 lbs a week"))
    }

    @Test func flatPaceHeldSteady() {
        let result = PaceCheckResult.step(reading(pace: -0.02), delta: -100, newCalories: 1_900, newAdjustment: -100)
        #expect(copy().sentence(for: result, phase: phase(), currentCalories: 2_000).contains("and your weight held about steady over"))
    }

    @Test func maintainStepNamesTheBand() {
        let result = PaceCheckResult.step(reading(pace: 0.2, goal: 0, trendKg: 80.8), delta: -100, newCalories: 2_300, newAdjustment: -100)
        #expect(
            copy().sentence(for: result, phase: phase(goal: .maintain), currentCalories: 2_400)
                == "Your trend is 0.8 kg above where you started, so we suggest 2,300 kcal, down from 2,400."
        )
    }

    @Test func noChangeSentencesCarryNoJudgement() {
        let judgement = ["fail", "behind", "only", "too slow", "too fast", "bad", "missed", "should"]
        let results: [PaceCheckResult] = [
            .notEnoughData(.waiting(daysLeft: 7)),
            .notEnoughData(.tooFewWeighIns(count: 3)),
            .notEnoughData(.spanTooShort(days: 6)),
            .targetReached(reading(pace: -0.4)),
            .onPace(reading(pace: -0.4)),
            .inBand(reading(pace: 0, goal: 0, trendKg: 80.2)),
            .inBand(reading(pace: -0.2, goal: 0, trendKg: 80.8)),
            .loggingGap(reading(pace: -0.1)),
            .atFloor(reading(pace: -0.1)),
        ]

        for result in results {
            let sentence = copy().sentence(for: result, phase: phase(), currentCalories: 2_000).lowercased()
            for word in judgement {
                #expect(!sentence.contains(word), "“\(word)” in: \(sentence)")
            }
        }
    }
}
