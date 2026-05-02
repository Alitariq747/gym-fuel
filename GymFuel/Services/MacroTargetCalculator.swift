import Foundation

struct MacroTargetCalculator {
    func targetMacros(for profile: UserProfile) -> Macros? {
        guard let age = profile.age,
              let heightCm = profile.heightCm,
              let weightKg = profile.weightKg else { return nil }

        let goal = profile.goalType ?? .defaultValue
        let activity = profile.nonTrainingActivityLevel ?? .somewhatActive
        let bmr = restingCalories(
            gender: profile.gender,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg
        )
        let targetCalories = (bmr * activity.multiplier) + goal.calorieOffset
        let protein = weightKg * goal.proteinPerKg
        let fat = weightKg * goal.fatPerKg
        let carbs = max(targetCalories - (protein * 4) - (fat * 9), 0) / 4

        return Macros(
            calories: targetCalories.rounded(),
            protein: protein.rounded(),
            carbs: carbs.rounded(),
            fat: fat.rounded()
        )
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

private extension NonTrainingActivityLevel {
    var multiplier: Double {
        switch self {
        case .mostlySitting: return 1.35
        case .somewhatActive: return 1.5
        case .physicallyDemanding: return 1.7
        }
    }
}

private extension GoalType {
    var calorieOffset: Double {
        switch self {
        case .leanBulk: return 250
        case .maintain: return 0
        case .cut: return -300
        }
    }

    var proteinPerKg: Double { self == .cut ? 2.2 : 1.8 }
    var fatPerKg: Double { self == .leanBulk ? 0.9 : 0.8 }
}
