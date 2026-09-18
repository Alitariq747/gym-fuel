import Foundation

/// A day's targets and the maintenance estimate they were worked out from.
struct MacroTargets: Equatable {
    let macros: Macros
    /// About how many kcal a day would keep the weight steady: the formula's
    /// estimate, rounded to 10. Never a measured burn, and never shown as one.
    let maintenanceCalories: Double
}

/// Works out daily targets from a profile, following `build-order.md` Step 4,
/// *The rules*. Pure: no Firebase, no UI.
struct MacroTargetCalculator {
    /// kcal in a kilogram of body weight gained or lost.
    static let caloriesPerKg: Double = 7_700
    /// Protein per kg of the basis weight, for every goal.
    static let proteinPerKg: Double = 1.6
    /// Calorie targets and the maintenance estimate round to this.
    static let calorieStep: Double = 10

    func targetMacros(for profile: UserProfile) -> Macros? {
        targets(for: profile)?.macros
    }

    func targets(for profile: UserProfile) -> MacroTargets? {
        guard let age = profile.age,
              let heightCm = profile.heightCm,
              let weightKg = profile.weightKg else { return nil }

        let goal = profile.goalType ?? .defaultValue
        let activity = profile.activityLevel ?? .lightlyActive
        let maintenance = restingCalories(
            gender: profile.gender,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg
        ) * activity.multiplier
        let dailyOffset = weightKg * goal.weeklyPace * Self.caloriesPerKg / 7

        // Until 4c adds a goal weight, the basis is the current weight, capped at
        // the top healthy weight for this height.
        let topHealthyWeightKg = SafetyLimits.weightKg(atBMI: SafetyLimits.topHealthyBMI, heightCm: heightCm)
        let basisKg = min(weightKg, topHealthyWeightKg)
        let protein = (basisKg * Self.proteinPerKg).rounded()
        let fat = (basisKg * goal.fatPerKg).rounded()

        let calories = max(
            Self.roundedToStep(maintenance + dailyOffset),
            Self.minimumCalories(gender: profile.gender, proteinG: protein, fatG: fat)
        )
        let carbs = ((calories - (protein * 4) - (fat * 9)) / 4).rounded()

        return MacroTargets(
            macros: Macros(calories: calories, protein: protein, carbs: carbs, fat: fat),
            maintenanceCalories: Self.roundedToStep(maintenance)
        )
    }

    /// The lowest calorie target allowed: the floor for `gender`, and never less
    /// than the protein and fat alone. Rounded **up** to 10, so carbs can never go
    /// negative.
    static func minimumCalories(gender: Gender, proteinG: Double, fatG: Double) -> Double {
        let minimum = max(SafetyLimits.calorieFloor(for: gender), (proteinG * 4) + (fatG * 9))
        return (minimum / calorieStep).rounded(.up) * calorieStep
    }

    private static func roundedToStep(_ calories: Double) -> Double {
        (calories / calorieStep).rounded() * calorieStep
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

extension ActivityLevel {
    /// Multiplier on resting energy, at the careful end of the measured ranges
    /// (FAO/WHO/UNU 2004). A number that is too high is the one that stalls weight
    /// loss.
    var multiplier: Double {
        switch self {
        case .mostlySitting: return 1.35
        case .lightlyActive: return 1.5
        case .active: return 1.7
        case .veryActive: return 1.9
        }
    }
}

extension GoalType {
    /// Share of body weight to change per week. Faster gain mostly adds fat.
    var weeklyPace: Double {
        switch self {
        case .leanBulk: return 0.0025
        case .maintain: return 0
        case .cut: return -0.005
        }
    }

    /// Fat per kg of the basis weight.
    var fatPerKg: Double { self == .leanBulk ? 0.9 : 0.8 }
}
