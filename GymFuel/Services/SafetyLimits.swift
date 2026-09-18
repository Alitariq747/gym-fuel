//
//  SafetyLimits.swift
//  GymFuel
//

import Foundation


enum SafetyLimits {
    /// The top of the healthy BMI range. Protein and fat are worked out from a
    /// weight no higher than this, so a bigger body does not get 300 g of protein
    /// and no carbs.
    static let topHealthyBMI: Double = 25

    /// Below this BMI, *Lose fat* is not offered.
    static let underweightBMI: Double = 18.5

    /// The ages the app accepts. 18 is the rule; 119 only keeps typos out.
    static let ageRange = 18...119

    /// No calorie target goes below this, including numbers the user types.
    static func calorieFloor(for gender: Gender) -> Double {
        switch gender {
        case .female: return 1_200
        case .male, .preferNotToSay: return 1_500
        }
    }

    /// The weight that gives `bmi` at `heightCm`.
    static func weightKg(atBMI bmi: Double, heightCm: Double) -> Double {
        let heightM = heightCm / 100
        return bmi * heightM * heightM
    }

    /// Why this age cannot be used, or nil when it can.
    static func ageProblem(_ age: Int?) -> String? {
        guard let age, age <= ageRange.upperBound else { return "Please enter a valid age." }
        guard age >= ageRange.lowerBound else {
            return "The equations behind your targets are only validated for adults, so you need to be \(ageRange.lowerBound) or over."
        }
        return nil
    }

    /// Why this goal cannot be chosen at this weight and height, or nil when it
    /// can. An unknown height or weight allows it — there is nothing to judge.
    static func goalProblem(_ goal: GoalType, weightKg: Double?, heightCm: Double?) -> String? {
        guard goal == .cut, let weightKg, let heightCm else { return nil }

        let lowestHealthyWeightKg = SafetyLimits.weightKg(atBMI: underweightBMI, heightCm: heightCm)
        guard weightKg < lowestHealthyWeightKg else { return nil }

        return "Not available when your weight is below the healthy range for your height."
    }
}
