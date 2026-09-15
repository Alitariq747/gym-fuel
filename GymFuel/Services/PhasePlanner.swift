//
//  PhasePlanner.swift
//  GymFuel
//

import Foundation

enum PhasePlan: Equatable {
    /// The current phase still describes the profile.
    case keep
    /// Write this phase, replacing any document with the same key.
    case start(Phase)
    /// Same goal and pace; only the target weight changed. Updated in place, so
    /// it cannot reset the check-in wait.
    case updateTargetWeight(Double?)
}

/// Decides whether a profile save starts a new phase.
///
/// Pure, like `WeighInImportPlanner`: every rule here fails as plausible data
/// rather than as a crash.
struct PhasePlanner {
    private let calculator: MacroTargetCalculator

    init(calculator: MacroTargetCalculator = MacroTargetCalculator()) {
        self.calculator = calculator
    }

    func plan(profile: UserProfile, current: Phase?, todayKey: String, now: Date) -> PhasePlan {
        guard profile.isOnboardingComplete,
              let goal = profile.goalType,
              let weightKg = profile.weightKg, weightKg > 0,
              !todayKey.isEmpty
        else { return .keep }

        let pace = profile.resolvedPace
        let targetWeightKg = profile.resolvedTargetWeightKg

        if let current, current.goalType == goal, current.goalPace == pace {
            return current.targetWeightKg == targetWeightKg ? .keep : .updateTargetWeight(targetWeightKg)
        }

        // The adjustment corrects the formula for this person, not for the goal,
        // so it carries across a goal or pace change (decision 8).
        let carriedAdjustment = current?.calorieAdjustment ?? 0
        guard let startTargets = calculator.targetMacros(for: profile, calorieAdjustment: carriedAdjustment) else {
            return .keep
        }

        // Never earlier than the current phase: a same-day change overwrites it,
        // and a clock that has moved backwards cannot reorder history.
        // Lexicographic order on zero-padded keys is chronological.
        let startDateKey = max(todayKey, current?.startDateKey ?? todayKey)

        return .start(
            Phase(
                startDateKey: startDateKey,
                goalType: goal,
                goalPace: pace,
                pacePercentPerWeek: pace?.percentPerWeek(for: goal) ?? 0,
                startWeightKg: weightKg,
                targetWeightKg: targetWeightKg,
                startTargets: startTargets,
                calorieAdjustment: carriedAdjustment,
                lastStepDecisionDateKey: nil,
                startedAt: now
            )
        )
    }
}
