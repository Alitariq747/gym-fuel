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

    @Test("Lose fat stops below BMI 18.5")
    func loseFatNeedsAHealthyWeight() {
        // BMI 18.5 at 150 cm is 41.625 kg.
        #expect(SafetyLimits.goalProblem(.cut, weightKg: 41.6, heightCm: 150) != nil)
        #expect(SafetyLimits.goalProblem(.cut, weightKg: 43, heightCm: 150) == nil)
        #expect(SafetyLimits.goalProblem(.cut, weightKg: 80, heightCm: 150) == nil)
    }

    @Test("Gain and Maintain are allowed at ordinary weights, and an unknown body blocks nothing")
    func otherGoalsAndUnknownBodies() {
        for goal in [GoalType.leanBulk, .maintain] {
            #expect(SafetyLimits.goalProblem(goal, weightKg: 40, heightCm: 180) == nil)
        }

        #expect(SafetyLimits.goalProblem(.cut, weightKg: nil, heightCm: 150) == nil)
        #expect(SafetyLimits.goalProblem(.cut, weightKg: 41.6, heightCm: nil) == nil)
    }

    // MARK: - Goal weight

    /// 41.7 kg at 150 cm is above BMI 18.5, but no whole kilo sits between
    /// 41.625 and 41.7 kg, so there would be no goal weight to pick.
    @Test("Lose fat also needs a goal weight left to pick")
    func loseFatNeedsRoomForAGoal() {
        let belowRange = SafetyLimits.goalProblem(.cut, weightKg: 41.6, heightCm: 150)
        let noRoom = SafetyLimits.goalProblem(.cut, weightKg: 41.7, heightCm: 150)

        #expect(noRoom != nil)
        #expect(noRoom != belowRange)
        // BMI 18.5 at 175 cm is 56.66 kg: at 57 kg no whole kilo fits below.
        #expect(SafetyLimits.goalProblem(.cut, weightKg: 57, heightCm: 175) != nil)
    }

    @Test("Gain stops only where no heavier weight can be recorded")
    func gainNeedsRoomForAGoal() {
        #expect(SafetyLimits.goalProblem(.leanBulk, weightKg: 199, heightCm: 175) == nil)
        #expect(SafetyLimits.goalProblem(.leanBulk, weightKg: 200, heightCm: 175) != nil)
    }

    @Test("A goal weight is on the goal's side of the current weight, never under BMI 18.5")
    func allowedGoalWeights() {
        // BMI 18.5 at 175 cm is 56.66 kg.
        #expect(SafetyLimits.allowsGoalWeight(84, for: .cut, currentWeightKg: 85, heightCm: 175))
        #expect(SafetyLimits.allowsGoalWeight(57, for: .cut, currentWeightKg: 85, heightCm: 175))
        #expect(!SafetyLimits.allowsGoalWeight(56, for: .cut, currentWeightKg: 85, heightCm: 175))
        #expect(!SafetyLimits.allowsGoalWeight(85, for: .cut, currentWeightKg: 85, heightCm: 175))

        #expect(SafetyLimits.allowsGoalWeight(86, for: .leanBulk, currentWeightKg: 85, heightCm: 175))
        #expect(!SafetyLimits.allowsGoalWeight(85, for: .leanBulk, currentWeightKg: 85, heightCm: 175))
        #expect(!SafetyLimits.allowsGoalWeight(201, for: .leanBulk, currentWeightKg: 85, heightCm: 175))

        #expect(!SafetyLimits.allowsGoalWeight(80, for: .maintain, currentWeightKg: 85, heightCm: 175))
    }

    @Test("The wheel offers every allowed whole kilo or pound, lightest first")
    func wheelOptions() {
        func options(_ goal: GoalType, _ unit: BodyWeightUnit) -> [Int] {
            SafetyLimits.goalWeightOptions(for: goal, currentWeightKg: 85, heightCm: 175, unit: unit)
        }

        #expect(options(.cut, .kilograms) == Array(57...84))
        #expect(options(.cut, .pounds) == Array(125...187))
        #expect(options(.leanBulk, .kilograms) == Array(86...200))
        #expect(options(.leanBulk, .pounds) == Array(188...440))
        #expect(options(.maintain, .kilograms).isEmpty)
    }
}
