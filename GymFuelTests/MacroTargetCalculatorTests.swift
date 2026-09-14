//
//  MacroTargetCalculatorTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("MacroTargetCalculator")
struct MacroTargetCalculatorTests {
    private let calculator = MacroTargetCalculator()

    private func person(
        gender: Gender = .male,
        age: Int = 30,
        heightCm: Double = 180,
        weightKg: Double = 80,
        activity: ActivityLevel = .mostlySitting,
        goal: GoalType,
        pace: GoalPace? = nil
    ) -> UserProfile {
        UserProfile(
            id: "test",
            name: "",
            heightCm: heightCm,
            age: age,
            weightKg: weightKg,
            goalType: goal,
            activityLevel: activity,
            isOnboardingComplete: true,
            gender: gender,
            goalPace: pace
        )
    }

    private func calories(_ profile: UserProfile) -> Double? {
        calculator.targetMacros(for: profile)?.calories
    }

    // Man, 30, 180 cm, 80 kg, mostly sitting: 1,780 resting × 1.35 = 2,403.

    @Test("Maintain is resting energy × activity, with no pace change")
    func maintain() {
        #expect(calories(person(goal: .maintain)) == 2_403)
    }

    @Test("Maintain ignores a leftover stored pace")
    func maintainIgnoresStoredPace() {
        #expect(calories(person(goal: .maintain, pace: .faster)) == 2_403)
    }

    @Test("Lose fat follows the pace: Steady −660, Faster −880")
    func cutFollowsPace() {
        #expect(calories(person(goal: .cut, pace: .steady)) == 1_743)
        #expect(calories(person(goal: .cut, pace: .faster)) == 1_523)
    }

    @Test("A missing pace on a cut is treated as Steady")
    func cutWithoutPaceIsSteady() {
        #expect(calories(person(goal: .cut)) == 1_743)
    }

    @Test("Gain follows the pace: Slow +220")
    func gainFollowsPace() {
        #expect(calories(person(goal: .leanBulk, pace: .slow)) == 2_623)
    }

    @Test("A small woman on Faster is held at the 1,200 kcal floor")
    func womanFloor() {
        let profile = person(gender: .female, age: 40, heightCm: 155, weightKg: 50, goal: .cut, pace: .faster)
        #expect(calories(profile) == 1_200)
    }

    @Test("A heavy woman on a cut never drops below protein + fat calories")
    func proteinAndFatFloor() throws {
        let profile = person(gender: .female, age: 40, heightCm: 165, weightKg: 120, goal: .cut, pace: .faster)
        let macros = try #require(calculator.targetMacros(for: profile))
        // 264 g protein × 4 + 96 g fat × 9 = 1,920
        #expect(macros.calories == 1_920)
        #expect(macros.carbs == 0)
    }

    @Test("The pace never takes more than 1,000 kcal a day off")
    func deficitCap() {
        // 2,280 resting × 1.5 = 3,420. Faster would be −1,430; capped at −1,000.
        let profile = person(weightKg: 130, activity: .somewhatActive, goal: .cut, pace: .faster)
        #expect(calories(profile) == 2_420)
    }

    @Test("Men and prefer-not-to-say share the 1,500 kcal floor")
    func otherFloors() {
        let man = person(age: 70, heightCm: 150, weightKg: 45, goal: .cut, pace: .faster)
        let unsaid = person(gender: .preferNotToSay, age: 70, heightCm: 150, weightKg: 45, goal: .cut, pace: .faster)
        #expect(calories(man) == 1_500)
        #expect(calories(unsaid) == 1_500)
    }

    @Test("Carbs are never negative")
    func carbsNeverNegative() {
        for goal in GoalType.allCases {
            for pace in GoalPace.allCases {
                let profile = person(gender: .female, age: 60, heightCm: 150, weightKg: 140, goal: goal, pace: pace)
                #expect((calculator.targetMacros(for: profile)?.carbs ?? -1) >= 0)
            }
        }
    }
}
