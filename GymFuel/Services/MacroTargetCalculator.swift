import Foundation

struct MacroTargetCalculator {
    /// Kilocalories per kilogram of body-weight change. A common planning
    /// estimate, not a measurement of anyone's body — Sources method 01 says so.
    static let kcalPerKg: Double = 7_700
    /// The most a pace may take off the daily target.
    static let maxDailyDeficit: Double = 1_000

    func targetMacros(for profile: UserProfile) -> Macros? {
        guard let age = profile.age,
              let heightCm = profile.heightCm,
              let weightKg = profile.weightKg else { return nil }

        let goal = profile.goalType ?? .defaultValue
        let activity = profile.activityLevel ?? .somewhatActive
        let bmr = restingCalories(
            gender: profile.gender,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg
        )
        let protein = weightKg * goal.proteinPerKg
        let fat = weightKg * goal.fatPerKg
        let proteinAndFatCalories = (protein * 4) + (fat * 9)

        // Base + pace, then the floors, then carbs take what is left.
        let pacedCalories = (bmr * activity.multiplier)
            + paceOffset(goal: goal, pace: profile.resolvedPace, weightKg: weightKg)
        let targetCalories = max(pacedCalories, profile.gender.calorieFloor, proteinAndFatCalories)
        let carbs = max(targetCalories - proteinAndFatCalories, 0) / 4

        return Macros(
            calories: targetCalories.rounded(),
            protein: protein.rounded(),
            carbs: carbs.rounded(),
            fat: fat.rounded()
        )
    }

    /// Daily calories added (gain) or taken off (loss) for the chosen pace.
    /// A loss is capped at `maxDailyDeficit`.
    private func paceOffset(goal: GoalType, pace: GoalPace?, weightKg: Double) -> Double {
        guard let pace else { return 0 }
        let offset = pace.kgPerWeek(for: goal, weightKg: weightKg) * Self.kcalPerKg / 7
        return max(offset, -Self.maxDailyDeficit)
    }

    private func restingCalories(
        gender: Gender,
        age: Int,
        heightCm: Double,
        weightKg: Double
    ) -> Double {
        let base = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age))
        switch gender {
        case .male: return base + 5
        case .female: return base - 161
        case .preferNotToSay: return base - 78
        }
    }
}

private extension ActivityLevel {
    var multiplier: Double {
        switch self {
        case .mostlySitting: return 1.35
        case .somewhatActive: return 1.5
        case .physicallyDemanding: return 1.7
        }
    }
}

private extension Gender {
    /// The lowest daily target the app will set.
    var calorieFloor: Double { self == .female ? 1_200 : 1_500 }
}

private extension GoalType {
    var proteinPerKg: Double { self == .cut ? 2.2 : 1.8 }
    var fatPerKg: Double { self == .leanBulk ? 0.9 : 0.8 }
}
