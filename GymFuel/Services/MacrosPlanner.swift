//
//  MacrosPlanner.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 11/12/2025.
//

import Foundation




/// Errors that can occur when planning daily macros.
enum MacrosPlannerError: Error {
    case missingBodyMetrics   // missing age/height/weight
}

/// Responsible for turning a UserProfile + DayLog (today's training context)
/// into a concrete macro target for the day.
struct MacrosPlanner {
    
    /// Main entry point.
    /// Given a user profile and today's day log (training settings),
    /// compute the target macros for this day.
    func planDailyMacros(
        profile: UserProfile,
        dayLog: DayLog
    ) throws -> Macros {
        
        // 1. Resolve required numeric inputs from profile.
        guard
            let weightKg = profile.weightKg,
            let heightCm = profile.heightCm,
            let ageYears = profile.age
        else {
            // In a real app you might want to handle this more gracefully.
            throw MacrosPlannerError.missingBodyMetrics
        }
        
        let isMale = profile.gender.lowercased().hasPrefix("m")
        
        let goal = profile.trainingGoal ?? .performance
        let experience = profile.trainingExperience ?? .intermediate
        let style = profile.trainingStyle ?? .mixed
        let activity = profile.nonTrainingActivityLevel ?? .mostlySitting
        let trainingDaysPerWeek = profile.trainingDaysPerWeek ?? 3
        
        // 2. Estimate BMR (resting calories) using Mifflin-St Jeor.
        let bmr = estimateBMR(
            weightKg: weightKg,
            heightCm: heightCm,
            ageYears: ageYears,
            isMale: isMale
        )
        
        // 3. Estimate non-training TDEE from BMR and lifestyle activity.
        let nonTrainingTDEE = bmr * activityMultiplier(for: activity)
        
        // 4. Add a training-day-specific adjustment based on intensity.
        let trainingAdjustment = trainingCalorieAdjustment(
            isTrainingDay: dayLog.isTrainingDay,
            intensity: dayLog.trainingIntensity
        )
        
        // 5. Compute a base "neutral" calorie target (before goal).
        let neutralCalories = nonTrainingTDEE + trainingAdjustment
        
        // 6. Adjust calories for goal (cut / maintain / gain / crush workouts).
        let goalAdjustedCalories = goalAdjustedCalorieTarget(
            neutralCalories: neutralCalories,
            goal: goal,
            experience: experience,
            intensity: dayLog.trainingIntensity,
            trainingDaysPerWeek: trainingDaysPerWeek
        )
        
        // 7. Split those calories into protein / fat / carbs.
        let macros = splitCaloriesIntoMacros(
            totalCalories: goalAdjustedCalories,
            weightKg: weightKg,
            goal: goal,
            experience: experience,
            style: style,
            sessionType: dayLog.sessionType
        )
        
        return macros
    }
}

// MARK: - BMR & Activity

private extension MacrosPlanner {
    
    /// Mifflin-St Jeor BMR equation.
    /// - For men:    BMR = 10W + 6.25H - 5A + 5
    /// - For women:  BMR = 10W + 6.25H - 5A - 161
    /// Where W = weight (kg), H = height (cm), A = age (years).
    func estimateBMR(
        weightKg: Double,
        heightCm: Double,
        ageYears: Int,
        isMale: Bool
    ) -> Double {
        let base = 10.0 * weightKg + 6.25 * heightCm - 5.0 * Double(ageYears)
        return base + (isMale ? 5.0 : -161.0)
    }
    
    /// Activity multiplier based on non-training activity level.
    func activityMultiplier(for level: NonTrainingActivityLevel) -> Double {
        switch level {
        case .mostlySitting:
            return 1.2    // desk job, mostly sedentary
        case .somewhatActive:
            return 1.4    // on feet sometimes
        case .physicallyDemanding:
            return 1.6    // physical work
        }
    }
}

// MARK: - Training-day adjustment & goal adjustment

private extension MacrosPlanner {
    
    /// Extra calories to account for today's training session.
    /// This is a rough estimate; we bias harder days higher.
    func trainingCalorieAdjustment(
        isTrainingDay: Bool,
        intensity: TrainingIntensity?
    ) -> Double {
        guard isTrainingDay else {
            return 0
        }
        
        switch intensity ?? .normal {
        case .recovery:
            return 150    // light cardio / deload
        case .normal:
            return 250
        case .hard:
            return 400
        case .allOut:
            return 550
        }
    }
    
    /// Adjust neutral calories up/down based on training goal and experience.
    func goalAdjustedCalorieTarget(
        neutralCalories: Double,
        goal: TrainingGoal,
        experience: TrainingExperience,
        intensity: TrainingIntensity?,
        trainingDaysPerWeek: Int
    ) -> Double {
        let intensity = intensity ?? .normal
        
        // Base multiplier depending on goal & experience.
        let multiplier: Double
        
        switch goal {
        case .fatLoss:
            // More experienced lifters usually need gentler deficits
            // to preserve performance & muscle mass.
            switch experience {
            case .beginner:
                multiplier = 0.80   // up to 20% deficit
            case .intermediate:
                multiplier = 0.85   // 15% deficit
            case .advanced:
                multiplier = 0.90   // 10% deficit
            }
            
        case .performance:
            // Keep the user near neutral, maybe a tiny bump on harder days.
            switch intensity {
            case .recovery:
                multiplier = 1.00
            case .normal:
                multiplier = 1.02
            case .hard, .allOut:
                multiplier = 1.05
            }
            
        case .muscleGain:
            // Small surplus for hypertrophy, slightly more if training frequently.
            let base: Double
            switch experience {
            case .beginner:
                base = 1.10
            case .intermediate:
                base = 1.12
            case .advanced:
                base = 1.15
            }
            
            // Very rough tweak: slightly higher surplus if they train 5+ days.
            if trainingDaysPerWeek >= 5 {
                multiplier = base + 0.02
            } else {
                multiplier = base
            }
            
        case .crushWorkouts:
            // Fuel performance first; small surplus on harder days.
            switch intensity {
            case .recovery:
                multiplier = 1.00
            case .normal:
                multiplier = 1.03
            case .hard, .allOut:
                multiplier = 1.08
            }
        }
        
        let adjusted = neutralCalories * multiplier
        
        // Clamp to a reasonable range to avoid extreme outputs.
        let minCalories = max(1400, neutralCalories * 0.7)
        let maxCalories = neutralCalories * 1.4
        
        return adjusted.clamped(to: minCalories...maxCalories)
    }
}

// MARK: - Macro splitting logic

private extension MacrosPlanner {
    
    /// Turn total calories into protein / fat / carbs, using
    /// bodyweight, goal, style, and experience.
    func splitCaloriesIntoMacros(
        totalCalories: Double,
        weightKg: Double,
        goal: TrainingGoal,
        experience: TrainingExperience,
        style: TrainingStyle,
        sessionType: SessionType?
    ) -> Macros {
        let sessionType = sessionType ?? mapStyleToSessionType(style)
        
        // 1. Determine protein grams per kg.
        let proteinPerKg = proteinPerKgRecommendation(
            weightKg: weightKg,
            goal: goal,
            experience: experience,
            sessionType: sessionType
        )
        let proteinGrams = proteinPerKg * weightKg
        let proteinCalories = proteinGrams * 4.0
        
        // 2. Determine fat grams per kg.
        let fatPerKg = fatPerKgRecommendation(
            weightKg: weightKg,
            goal: goal,
            sessionType: sessionType
        )
        let fatGrams = fatPerKg * weightKg
        let fatCalories = fatGrams * 9.0
        
        // 3. Carbs take remaining calories.
        var remainingCalories = totalCalories - proteinCalories - fatCalories
        
        // Ensure we don't go negative; if the target is very low,
        // sacrifice some carbs but keep protein & fat minima.
        let minimumCarbCalories = totalCalories * 0.10   // at least 10% from carbs
        if remainingCalories < minimumCarbCalories {
            remainingCalories = minimumCarbCalories
        }
        
        let carbGrams = remainingCalories / 4.0
        
        return Macros(
            calories: totalCalories.rounded(),
            protein: proteinGrams.rounded(),
            carbs: carbGrams.rounded(),
            fat: fatGrams.rounded()
        )
    }
    
    /// Fallback mapping from long-term training style to today's session type
    /// when the sessionType is nil on the DayLog.
    func mapStyleToSessionType(_ style: TrainingStyle) -> SessionType {
        switch style {
        case .strength:
            return .strength
        case .hypertrophy:
            return .hypertrophy
        case .mixed:
            return .mixed
        case .endurance:
            return .endurance
        }
    }
    
    /// Protein recommendations in g/kg.
    func proteinPerKgRecommendation(
        weightKg: Double,
        goal: TrainingGoal,
        experience: TrainingExperience,
        sessionType: SessionType
    ) -> Double {
        // Base by session type.
        let base: Double
        switch sessionType {
        case .strength, .hypertrophy:
            base = 1.8
        case .mixed:
            base = 1.7
        case .endurance:
            base = 1.6
        }
        
        var recommended = base
        
        // Higher protein for fat loss to preserve muscle.
        if goal == .fatLoss {
            recommended += 0.2
        }
        
        // Very experienced lifters often benefit from slightly higher protein.
        if experience == .advanced {
            recommended += 0.1
        }
        
        // Clamp to a realistic range.
        return recommended.clamped(to: 1.6...2.4)
    }
    
    /// Fat recommendations in g/kg.
    func fatPerKgRecommendation(
        weightKg: Double,
        goal: TrainingGoal,
        sessionType: SessionType
    ) -> Double {
        // Base fat intake.
        var base = 0.8
        
        // Slightly lower fat for endurance or high-carb bias.
        if sessionType == .endurance || sessionType == .mixed {
            base = 0.7
        }
        
        // For aggressive fat loss, we can drop fat a bit but not too low.
        if goal == .fatLoss {
            base -= 0.05
        }
        
        // Clamp to a safe range: don't go too low or too high.
        return base.clamped(to: 0.5...1.0)
    }
}

// MARK: - Small helpers

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
