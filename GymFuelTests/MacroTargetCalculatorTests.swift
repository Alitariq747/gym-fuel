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

    private func targets(
        _ gender: Gender,
        age: Int,
        heightCm: Double,
        weightKg: Double,
        goal: GoalType,
        activity: ActivityLevel,
        goalWeightKg: Double? = nil
    ) -> MacroTargets? {
        calculator.targets(for: UserProfile(
            name: "",
            heightCm: heightCm,
            age: age,
            weightKg: weightKg,
            goalType: goal,
            activityLevel: activity,
            isOnboardingComplete: true,
            gender: gender,
            goalWeightKg: goalWeightKg
        ))
    }

    private func expected(
        kcal: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        maintenance: Double
    ) -> MacroTargets {
        MacroTargets(
            macros: Macros(calories: kcal, protein: protein, carbs: carbs, fat: fat),
            maintenanceCalories: maintenance
        )
    }

    // MARK: - The 17 September scan

    /// 951 kcal before Step 4b.
    @Test("A 45 kg, 150 cm, 60-year-old woman losing fat gets the 1,200 kcal floor")
    func smallOlderWomanGetsFloor() {
        let result = targets(.female, age: 60, heightCm: 150, weightKg: 45, goal: .cut, activity: .mostlySitting)
        #expect(result == expected(kcal: 1_200, protein: 72, carbs: 147, fat: 36, maintenance: 1_250))
    }

    /// 82 g of carbs before Step 4b, from 242 g of protein on full body weight.
    @Test("A 110 kg woman losing fat keeps normal carbs")
    func heavierWomanKeepsCarbs() {
        let result = targets(.female, age: 40, heightCm: 165, weightKg: 110, goal: .cut, activity: .mostlySitting)
        #expect(result == expected(kcal: 1_780, protein: 109, carbs: 215, fat: 54, maintenance: 2_390))
    }

    /// 0 g of carbs before Step 4b: protein and fat alone were over the target.
    @Test("A 200 kg woman losing fat keeps normal carbs")
    func veryHeavyWomanKeepsCarbs() {
        let result = targets(.female, age: 60, heightCm: 150, weightKg: 200, goal: .cut, activity: .mostlySitting)
        #expect(result == expected(kcal: 2_240, protein: 90, carbs: 369, fat: 45, maintenance: 3_340))
    }

    // MARK: - Pace

    @Test("Losing at 85 kg takes about 470 kcal a day off maintenance")
    func losingPace() throws {
        let result = try #require(targets(.male, age: 30, heightCm: 180, weightKg: 85, goal: .cut, activity: .mostlySitting))

        #expect(result == expected(kcal: 2_000, protein: 130, carbs: 224, fat: 65, maintenance: 2_470))
        #expect(result.maintenanceCalories - result.macros.calories == 470)
    }

    @Test("Gaining at 70 kg adds about 190 kcal a day to maintenance")
    func gainingPace() throws {
        let result = try #require(targets(.male, age: 25, heightCm: 175, weightKg: 70, goal: .leanBulk, activity: .lightlyActive))

        #expect(result == expected(kcal: 2_700, protein: 112, carbs: 421, fat: 63, maintenance: 2_510))
        #expect(result.macros.calories - result.maintenanceCalories == 190)
    }

    @Test("Maintaining targets the maintenance estimate")
    func maintainHasNoOffset() throws {
        let result = try #require(targets(.female, age: 30, heightCm: 165, weightKg: 60, goal: .maintain, activity: .lightlyActive))

        #expect(result == expected(kcal: 1_980, protein: 96, carbs: 291, fat: 48, maintenance: 1_980))
    }

    // MARK: - Activity

    @Test("Activity multipliers are 1.35, 1.5, 1.7 and 1.9")
    func activityMultipliers() {
        #expect(ActivityLevel.allCases.map(\.multiplier) == [1.35, 1.5, 1.7, 1.9])
    }

    @Test("Very active uses the 1.9 multiplier")
    func veryActive() {
        let result = targets(.female, age: 32, heightCm: 168, weightKg: 65, goal: .maintain, activity: .veryActive)
        #expect(result == expected(kcal: 2_620, protein: 104, carbs: 434, fat: 52, maintenance: 2_620))
    }

    // MARK: - Floors and basis

    @Test("Men and prefer not to say get the 1,500 kcal floor")
    func higherFloor() {
        let male = targets(.male, age: 70, heightCm: 160, weightKg: 50, goal: .cut, activity: .mostlySitting)
        let unsaid = targets(.preferNotToSay, age: 70, heightCm: 160, weightKg: 50, goal: .cut, activity: .mostlySitting)

        #expect(male == expected(kcal: 1_500, protein: 80, carbs: 205, fat: 40, maintenance: 1_560))
        #expect(unsaid == expected(kcal: 1_500, protein: 80, carbs: 205, fat: 40, maintenance: 1_450))
    }

    @Test("Protein and fat stop growing above the BMI 25 weight")
    func basisIsCapped() throws {
        let heavier = try #require(targets(.female, age: 40, heightCm: 150, weightKg: 100, goal: .cut, activity: .mostlySitting))
        let heaviest = try #require(targets(.female, age: 40, heightCm: 150, weightKg: 200, goal: .cut, activity: .mostlySitting))

        #expect(heavier.macros.protein == heaviest.macros.protein)
        #expect(heavier.macros.fat == heaviest.macros.fat)
    }

    @Test("Gaining takes protein and fat from the goal weight, capped at the BMI 25 weight")
    func gainingUsesGoalWeight() throws {
        // BMI 25 at 180 cm is 81 kg, below the 90 kg goal.
        let result = try #require(targets(.male, age: 30, heightCm: 180, weightKg: 75, goal: .leanBulk, activity: .lightlyActive, goalWeightKg: 90))

        #expect(result.macros.protein == 130)
        #expect(result.macros.fat == 73)
    }

    @Test("Losing takes protein and fat from the goal weight")
    func losingUsesGoalWeight() throws {
        // BMI 25 at 185 cm is 85.6 kg, above the 82 kg goal.
        let result = try #require(targets(.male, age: 35, heightCm: 185, weightKg: 90, goal: .cut, activity: .mostlySitting, goalWeightKg: 82))

        #expect(result.macros.protein == 131)
        #expect(result.macros.fat == 66)
    }

    @Test("Maintaining ignores a goal weight left over from another goal")
    func maintainIgnoresGoalWeight() {
        let result = targets(.female, age: 30, heightCm: 165, weightKg: 60, goal: .maintain, activity: .lightlyActive, goalWeightKg: 50)
        #expect(result == expected(kcal: 1_980, protein: 96, carbs: 291, fat: 48, maintenance: 1_980))
    }

    @Test("The minimum never falls below protein and fat, and rounds up")
    func minimumCalories() {
        // 150 g protein + 80 g fat = 1,320 kcal, above the 1,200 floor.
        #expect(MacroTargetCalculator.minimumCalories(gender: .female, proteinG: 150, fatG: 80) == 1_320)
        // 1,324 kcal rounds up, not to the nearest 10, or carbs would go negative.
        #expect(MacroTargetCalculator.minimumCalories(gender: .female, proteinG: 151, fatG: 80) == 1_330)
        #expect(MacroTargetCalculator.minimumCalories(gender: .female, proteinG: 50, fatG: 30) == 1_200)
        #expect(MacroTargetCalculator.minimumCalories(gender: .male, proteinG: 50, fatG: 30) == 1_500)
    }

    @Test("A missing age, height or weight gives no targets")
    func missingInputs() {
        var profile = UserProfile(
            name: "",
            heightCm: 165,
            age: 30,
            weightKg: 60,
            goalType: .maintain,
            activityLevel: .mostlySitting,
            isOnboardingComplete: true,
            gender: .female
        )
        #expect(calculator.targets(for: profile) != nil)

        profile.age = nil
        #expect(calculator.targets(for: profile) == nil)

        profile.age = 30
        profile.heightCm = nil
        #expect(calculator.targets(for: profile) == nil)

        profile.heightCm = 165
        profile.weightKg = nil
        #expect(calculator.targets(for: profile) == nil)
    }

    /// Every body the pickers allow, at both ends of the age range.
    @Test("Calories are multiples of 10, never below the floor, and carbs never go negative")
    func invariantsHoldEverywhere() {
        for gender in Gender.allCases {
            for goal in GoalType.allCases {
                for activity in ActivityLevel.allCases {
                    for heightCm in stride(from: 140.0, through: 210.0, by: 10) {
                        for weightKg in stride(from: 30.0, through: 200.0, by: 10) {
                            for age in [18, 60, 119] {
                                let label = "\(gender) \(goal) \(activity) \(heightCm) cm \(weightKg) kg \(age) y"
                                guard let macros = targets(gender, age: age, heightCm: heightCm, weightKg: weightKg, goal: goal, activity: activity)?.macros else {
                                    Issue.record("no targets for \(label)")
                                    continue
                                }

                                #expect(macros.calories.truncatingRemainder(dividingBy: 10) == 0, "\(label)")
                                #expect(macros.calories >= SafetyLimits.calorieFloor(for: gender), "\(label)")
                                #expect(macros.carbs >= 0, "\(label)")
                            }
                        }
                    }
                }
            }
        }
    }
}
