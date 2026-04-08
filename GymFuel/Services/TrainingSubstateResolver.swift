//
//  TrainingSubstateResolver.swift
//  GymFuel
//
//  Resolves phase-specific substates.
//
//

import Foundation

struct TrainingSubstateResolver {
    /// Entry point for phase-based substate resolution.

    
    func resolveSubstate(
        for phase: TrainingPhase,
        context: SessionStateContext
    ) -> TrainingSubstate? {
        switch phase {
        case .scheduled:
            return .scheduled(resolveScheduledSubstate(context: context))
        case .preWorkout:
            return .preWorkout(resolvePreWorkoutSubstate(context: context))
        case .inWorkout:
            return .inWorkout(resolveInWorkoutSubstate(context: context))
        case .postWorkout:
            return .postWorkout(resolvePostWorkoutSubstate(context: context))
        case .support:
            return .support(resolveSupportSubstate(context: context))
        }
    }

    func resolveScheduledSubstate(context: SessionStateContext) -> ScheduledSubstate {
        let calorieProgress = context.calorieProgress
        let proteinProgress = context.proteinProgress
        let carbProgress = context.carbProgress
        let fatProgress = context.fatProgress

        // Overshoot should be driven mainly by calories + fat.
        let calorieOrFatOvershoot = calorieProgress >= 1.08 || fatProgress >= 1.18
        let hardOvershoot = calorieProgress >= 1.18 || fatProgress >= 1.30
        let broadOvershoot = calorieProgress >= 1.05 && (fatProgress >= 1.05 || carbProgress >= 1.20 || proteinProgress >= 1.25)

        if hardOvershoot || calorieOrFatOvershoot || broadOvershoot {
            return .overFueled
        }

        // Under-fuel should be driven mainly by calories + carbs.
        let calorieAndCarbLow = calorieProgress < 0.30 && carbProgress < 0.35
        let severeUnderfuel = calorieProgress < 0.20 || carbProgress < 0.20
        let broadUnderfuel = calorieProgress < 0.25 && carbProgress < 0.30 && proteinProgress < 0.35

        if severeUnderfuel || calorieAndCarbLow || broadUnderfuel {
            return .underFueled
        }

        return .onTarget
    }

    func resolvePreWorkoutSubstate(context: SessionStateContext) -> PreWorkoutSubstate {
        let preCalories = context.preWorkoutConsumedMacros.calories
        let preCarbs = context.preWorkoutConsumedMacros.carbs
        let preProtein = context.preWorkoutConsumedMacros.protein
        let preFat = context.preWorkoutConsumedMacros.fat
        let minutesUntilSessionStart = minutesUntilSessionStart(context: context)

        // If session is close and little-to-no pre-fuel is logged, prioritize eating first.
        if let minutesUntilSessionStart,
           minutesUntilSessionStart <= 60,
           preCalories < 120 {
            return .needPreMeal
        }

        // Carbs are still too low for this phase.
        if preCarbs < 20 {
            return .lowCarbPre
        }

        // Heavy pre-workout intake: calories and/or fats are already above a practical range.
        if preCalories >= 450 || preFat >= 18 {
            return .heavy
        }

        // Strong pre-workout intake already in place.
        if preCalories >= 300, preCarbs >= 45, preProtein >= 20 {
            return .onTarget
        }

        // A meaningful pre-workout meal exists, but not fully optimal yet.
        return .onTarget
    }

    func resolveInWorkoutSubstate(context: SessionStateContext) -> InWorkoutSubstate {
        // Product choice for v1: keep in-workout guidance simple and always
        // reinforce steady hydration + controlled effort.
        _ = context
        return .hydratedAndFueled
    }

    func resolvePostWorkoutSubstate(context: SessionStateContext) -> PostWorkoutSubstate {
        let postCalories = context.postWorkoutConsumedMacros.calories
        let postProtein = context.postWorkoutConsumedMacros.protein
        let postCarbs = context.postWorkoutConsumedMacros.carbs
        let minutesSinceSessionEnd = minutesSinceSessionEnd(context: context)

        // If we're in the early recovery window and almost nothing is logged yet,
        // prioritize getting the first recovery meal in.
        if let minutesSinceSessionEnd,
           minutesSinceSessionEnd <= 90,
           postCalories < 150 {
            return .needRecoveryMeal
        }

        // Protein is the primary recovery signal for tissue repair.
        if postProtein < 20 {
            return .lowProteinRecovery
        }

        // Carbs replenish glycogen after the session.
        if postCarbs < 30 {
            return .lowCarbRecovery
        }

        // Recovery intake is in a healthy range.
        return .recoveryOnTrack
    }

    func resolveSupportSubstate(context: SessionStateContext) -> SupportSubstate {
        let calorieProgress = context.calorieProgress
        let proteinProgress = context.proteinProgress
        let carbProgress = context.carbProgress
        let fatProgress = context.fatProgress

        // Support-phase overshoot: calories + fat matter most.
        let hardOvershoot = calorieProgress >= 1.15 || fatProgress >= 1.25
        let practicalOvershoot = calorieProgress >= 1.05 && (fatProgress >= 1.05 || carbProgress >= 1.15 || proteinProgress >= 1.20)
        let fatLedOvershoot = fatProgress >= 1.18 && calorieProgress >= 1.00

        if hardOvershoot || practicalOvershoot || fatLedOvershoot {
            return .overFueled
        }

        // Support-phase underfuel: calories + carbs matter most.
        let severeUnderfuel = calorieProgress < 0.75 || carbProgress < 0.70
        let practicalUnderfuel = calorieProgress < 0.90 && carbProgress < 0.90
        let broadUnderfuel = calorieProgress < 0.85 && carbProgress < 0.85 && proteinProgress < 0.85

        if severeUnderfuel || practicalUnderfuel || broadUnderfuel {
            return .underFueled
        }

        return .onTarget
    }
}

private extension TrainingSubstateResolver {

    func minutesUntilPreWorkoutWindow(context: SessionStateContext) -> Int? {
        guard let sessionStart = context.sessionStart else { return nil }

        let preWindowStart = Calendar.current.date(
            byAdding: .minute,
            value: -context.preWorkoutLeadMinutes,
            to: sessionStart
        ) ?? sessionStart

        let seconds = preWindowStart.timeIntervalSince(context.now)
        return Int(seconds / 60.0)
    }

    func minutesUntilSessionStart(context: SessionStateContext) -> Int? {
        guard let sessionStart = context.sessionStart else { return nil }
        let seconds = sessionStart.timeIntervalSince(context.now)
        return Int(seconds / 60.0)
    }

    func minutesSinceSessionEnd(context: SessionStateContext) -> Int? {
        guard let sessionEnd = context.sessionEnd else { return nil }
        let seconds = context.now.timeIntervalSince(sessionEnd)
        return Int(seconds / 60.0)
    }
}
