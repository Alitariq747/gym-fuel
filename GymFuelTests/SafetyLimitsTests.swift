//
//  SafetyLimitsTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("SafetyLimits")
struct SafetyLimitsTests {
    @Test("Women have a 1,200 kcal floor; men and prefer not to say 1,500")
    func calorieFloors() {
        #expect(SafetyLimits.calorieFloor(for: .female) == 1_200)
        #expect(SafetyLimits.calorieFloor(for: .male) == 1_500)
        #expect(SafetyLimits.calorieFloor(for: .preferNotToSay) == 1_500)
    }

    @Test("The weight at a BMI follows weight = BMI × height²")
    func weightAtBMI() {
        #expect(SafetyLimits.weightKg(atBMI: SafetyLimits.topHealthyBMI, heightCm: 150) == 56.25)
        #expect(abs(SafetyLimits.weightKg(atBMI: SafetyLimits.topHealthyBMI, heightCm: 180) - 81) < 1e-9)
    }

    @Test("An age under 18, over 119 or missing cannot be used")
    func ages() {
        #expect(SafetyLimits.ageProblem(nil) != nil)
        #expect(SafetyLimits.ageProblem(0) != nil)
        #expect(SafetyLimits.ageProblem(17) != nil)
        #expect(SafetyLimits.ageProblem(18) == nil)
        #expect(SafetyLimits.ageProblem(119) == nil)
        #expect(SafetyLimits.ageProblem(120) != nil)
    }

    /// Someone too young is told the limit, not just that the age is invalid.
    @Test("Under 18 is told the limit")
    func underAgeSaysTheLimit() {
        #expect(SafetyLimits.ageProblem(17)?.contains("18") == true)
    }

    @Test("Lose fat stops below BMI 18.5 and is allowed at or above it")
    func loseFatNeedsAHealthyWeight() {
        // BMI 18.5 at 150 cm is 41.625 kg.
        #expect(SafetyLimits.goalProblem(.cut, weightKg: 41.6, heightCm: 150) != nil)
        #expect(SafetyLimits.goalProblem(.cut, weightKg: 41.7, heightCm: 150) == nil)
        #expect(SafetyLimits.goalProblem(.cut, weightKg: 80, heightCm: 150) == nil)
    }

    @Test("Gain and Maintain are never blocked, and an unknown body blocks nothing")
    func otherGoalsAndUnknownBodies() {
        for goal in [GoalType.leanBulk, .maintain] {
            #expect(SafetyLimits.goalProblem(goal, weightKg: 40, heightCm: 180) == nil)
        }

        #expect(SafetyLimits.goalProblem(.cut, weightKg: nil, heightCm: 150) == nil)
        #expect(SafetyLimits.goalProblem(.cut, weightKg: 41.6, heightCm: nil) == nil)
    }
}
