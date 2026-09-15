//
//  TargetWeightTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("TargetWeight")
struct TargetWeightTests {
    // 180 cm: BMI 18.5 is 18.5 × 1.8² = 59.94 kg.

    @Test("The underweight line is BMI 18.5 for the height")
    func lowestHealthyWeight() {
        #expect(abs(TargetWeight.lowestHealthyKg(heightCm: 180) - 59.94) < 1e-9)
    }

    @Test("Lose fat allows from the underweight line up to just below today's weight")
    func cutRange() {
        let range = TargetWeight.allowedRange(goal: .cut, currentWeightKg: 80, heightCm: 180)
        #expect(range == 59.94...79.9)
    }

    @Test("Gain allows from just above today's weight")
    func gainRange() {
        let range = TargetWeight.allowedRange(goal: .leanBulk, currentWeightKg: 80, heightCm: 180)
        #expect(range == 80.1...BodyWeight.maximumKilograms)
    }

    @Test("Gain from underweight still starts at the underweight line")
    func gainFromUnderweight() {
        let range = TargetWeight.allowedRange(goal: .leanBulk, currentWeightKg: 50, heightCm: 180)
        #expect(range?.lowerBound == 59.94)
    }

    @Test("Maintain has no target weight")
    func maintainHasNone() {
        #expect(TargetWeight.allowedRange(goal: .maintain, currentWeightKg: 80, heightCm: 180) == nil)
    }

    @Test("Losing from the underweight line has nowhere to go")
    func cutAtUnderweightLine() {
        #expect(TargetWeight.allowedRange(goal: .cut, currentWeightKg: 59, heightCm: 180) == nil)
    }

    @Test("Missing height or weight gives no range")
    func missingInputs() {
        #expect(TargetWeight.allowedRange(goal: .cut, currentWeightKg: 80, heightCm: nil) == nil)
        #expect(TargetWeight.allowedRange(goal: .cut, currentWeightKg: nil, heightCm: 180) == nil)
    }

    @Test("Validity follows the range, and no target is always valid")
    func validity() {
        func valid(_ target: Double?, _ goal: GoalType) -> Bool {
            TargetWeight.isValid(target, goal: goal, currentWeightKg: 80, heightCm: 180)
        }

        #expect(valid(nil, .cut))
        #expect(valid(nil, .maintain))
        #expect(valid(70, .cut))
        #expect(valid(59.94, .cut))
        #expect(!valid(80, .cut))
        #expect(!valid(59.9, .cut))
        #expect(!valid(79, .leanBulk))
        #expect(valid(85, .leanBulk))
        #expect(!valid(70, .maintain))
    }

    @Test("A stored target weight survives only while the goal has one")
    func profileResolvesByGoalOnly() {
        var profile = UserProfile(
            id: "test", name: "", heightCm: 180, age: 30, weightKg: 70,
            goalType: .cut, activityLevel: .mostlySitting,
            isOnboardingComplete: true, gender: .male, targetWeightKg: 72
        )
        // Already below the target — reached, and still set.
        #expect(profile.resolvedTargetWeightKg == 72)

        profile.goalType = .maintain
        #expect(profile.resolvedTargetWeightKg == nil)
    }
}
