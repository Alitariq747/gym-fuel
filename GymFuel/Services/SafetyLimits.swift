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

    /// Below this BMI, *Lose fat* is not offered and no goal weight is allowed.
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
        guard goal != .maintain, let weightKg, let heightCm else { return nil }

        let lowestHealthyWeightKg = SafetyLimits.weightKg(atBMI: underweightBMI, heightCm: heightCm)
        if goal == .cut, weightKg < lowestHealthyWeightKg {
            return "Not available when your weight is below the healthy range for your height."
        }

        // The goal weight step offers whole kilos or pounds. With none to offer
        // in either unit, this goal would lead nowhere.
        let hasGoalWeights = BodyWeightUnit.allCases.allSatisfy { unit in
            !goalWeightOptions(for: goal, currentWeightKg: weightKg, heightCm: heightCm, unit: unit).isEmpty
        }
        guard !hasGoalWeights else { return nil }

        return goal == .cut
            ? "Not available this close to the lowest healthy weight for your height."
            : "Not available at this weight."
    }

    /// Whether `goalWeightKg` can be the goal for `goal`: below the current weight
    /// but not under BMI 18.5 when losing, above it when gaining, and within the
    /// weights the app records. Maintain has no goal weight.
    static func allowsGoalWeight(_ goalWeightKg: Double, for goal: GoalType, currentWeightKg: Double, heightCm: Double) -> Bool {
        guard goalWeightKg >= BodyWeight.minimumKilograms,
              goalWeightKg <= BodyWeight.maximumKilograms else { return false }

        switch goal {
        case .cut:
            return goalWeightKg < currentWeightKg
                && goalWeightKg >= SafetyLimits.weightKg(atBMI: underweightBMI, heightCm: heightCm)
        case .leanBulk:
            return goalWeightKg > currentWeightKg
        case .maintain:
            return false
        }
    }

    /// The goal weights the goal weight step offers: every whole kilo or pound
    /// that `allowsGoalWeight` accepts, lightest first.
    static func goalWeightOptions(for goal: GoalType, currentWeightKg: Double, heightCm: Double, unit: BodyWeightUnit) -> [Int] {
        let lowest = BodyWeight.minimumKilograms
        let highest = BodyWeight.maximumKilograms
        let candidates = unit == .kilograms
            ? Int(lowest)...Int(highest)
            : Int(BodyWeight.pounds(fromKilograms: lowest))...Int(BodyWeight.pounds(fromKilograms: highest))

        return candidates.filter { value in
            let kg = unit == .kilograms ? Double(value) : BodyWeight.kilograms(fromPounds: Double(value))
            return allowsGoalWeight(kg, for: goal, currentWeightKg: currentWeightKg, heightCm: heightCm)
        }
    }
}
