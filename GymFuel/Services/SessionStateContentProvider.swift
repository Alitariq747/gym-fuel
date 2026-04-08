//
//  SessionStateContentProvider.swift
//  GymFuel
//
//  Maps (phase + substate + tone) into UI copy.

//

import Foundation

struct SessionStateContentProvider {
    func resolveContent(
        dayMode: DayMode,
        substate: TrainingSubstate?,
        tone: SessionTone
    ) -> SessionStateContent {
        if case .training(.scheduled) = dayMode,
           case .scheduled(let scheduledSubstate) = substate {
            return scheduledContent(for: scheduledSubstate, tone: tone)
        }

        if case .training(.preWorkout) = dayMode,
           case .preWorkout(let preWorkoutSubstate) = substate {
            return preWorkoutContent(for: preWorkoutSubstate, tone: tone)
        }

        if case .training(.inWorkout) = dayMode,
           case .inWorkout(let inWorkoutSubstate) = substate {
            return inWorkoutContent(for: inWorkoutSubstate, tone: tone)
        }

        if case .training(.postWorkout) = dayMode,
           case .postWorkout(let postWorkoutSubstate) = substate {
            return postWorkoutContent(for: postWorkoutSubstate, tone: tone)
        }

        if case .training(.support) = dayMode,
           case .support(let supportSubstate) = substate {
            return supportContent(for: supportSubstate, tone: tone)
        }

        // Generic fallback for all other combinations until we expand mapping.
        return fallbackContent(dayMode: dayMode, tone: tone)
    }
}

private extension SessionStateContentProvider {
    func scheduledContent(for substate: ScheduledSubstate, tone: SessionTone) -> SessionStateContent {
        switch substate {
        case .onTarget:
            return onTargetScheduledContent(tone: tone)
        case .underFueled:
            return underFueledScheduledContent(tone: tone)
        case .overFueled:
            return overFueledScheduledContent(tone: tone)
        }
    }

    func preWorkoutContent(for substate: PreWorkoutSubstate, tone: SessionTone) -> SessionStateContent {
        switch substate {
        case .needPreMeal:
            return needPreMealContent(tone: tone)
        case .lowCarbPre:
            return lowCarbPreContent(tone: tone)
        case .heavy:
            return heavyPreWorkoutContent(tone: tone)
        case .onTarget:
            return onTargetPreWorkoutContent(tone: tone)
        }
    }

    func inWorkoutContent(for substate: InWorkoutSubstate, tone: SessionTone) -> SessionStateContent {
        switch substate {
        case .hydratedAndFueled:
            return hydratedAndFueledContent(tone: tone)
        }
    }

    func postWorkoutContent(for substate: PostWorkoutSubstate, tone: SessionTone) -> SessionStateContent {
        switch substate {
        case .needRecoveryMeal:
            return needRecoveryMealContent(tone: tone)
        case .lowProteinRecovery:
            return lowProteinRecoveryContent(tone: tone)
        case .lowCarbRecovery:
            return lowCarbRecoveryContent(tone: tone)
        case .recoveryOnTrack:
            return recoveryOnTrackContent(tone: tone)
        }
    }

    func supportContent(for substate: SupportSubstate, tone: SessionTone) -> SessionStateContent {
        switch substate {
        case .underFueled:
            return underFueledSupportContent(tone: tone)
        case .onTarget:
            return onTargetSupportContent(tone: tone)
        case .overFueled:
            return overFueledSupportContent(tone: tone)
        }
    }

    func needPreMealContent(tone: SessionTone) -> SessionStateContent {
        switch tone {
        case .calm, .recovery:
            return SessionStateContent(
                title: "Pre-Workout Meal Needed",
                message: "Your session is near and pre-fuel is still light.",
                nextRecommendation: "Add an easy pre-workout meal now.",
                tone: tone
            )
        case .focused:
            return SessionStateContent(
                title: "Fuel Before Session",
                message: "You are entering training soon without enough pre-fuel.",
                nextRecommendation: "Log a carb + protein pre-workout meal immediately.",
                tone: tone
            )
        case .assertive:
            return SessionStateContent(
                title: "Fuel Gap Before Lift",
                message: "Session start is close and intake is too low.",
                nextRecommendation: "Take quick carbs and protein now to avoid a flat session.",
                tone: tone
            )
        }
    }

    func lowCarbPreContent(tone: SessionTone) -> SessionStateContent {
        switch tone {
        case .calm, .recovery:
            return SessionStateContent(
                title: "Carbs Still Low",
                message: "Pre-workout carbs are below your ideal range.",
                nextRecommendation: "Add a small carb-focused top-up before training.",
                tone: tone
            )
        case .focused:
            return SessionStateContent(
                title: "Build Pre Carbs",
                message: "Carbohydrate support is still short for this session.",
                nextRecommendation: "Aim for a 20-40g carb addition now.",
                tone: tone
            )
        case .assertive:
            return SessionStateContent(
                title: "Low Carb Readiness",
                message: "Carb intake is too low for the upcoming workload.",
                nextRecommendation: "Add fast carbs immediately and enter training fueled.",
                tone: tone
            )
        }
    }

    func heavyPreWorkoutContent(tone: SessionTone) -> SessionStateContent {
        switch tone {
        case .calm, .recovery:
            return SessionStateContent(
                title: "Pre-Workout Meal Is Heavy",
                message: "Your pre-workout intake is on the heavy side.",
                nextRecommendation: "Keep the next intake light and hydrate before training.",
                tone: tone
            )
        case .focused:
            return SessionStateContent(
                title: "Heavy Pre-Workout Load",
                message: "Calories and/or fats are high for this pre-session window.",
                nextRecommendation: "Avoid extra fats now and keep hydration steady.",
                tone: tone
            )
        case .assertive:
            return SessionStateContent(
                title: "Too Heavy Before Session",
                message: "Pre-workout load is heavier than ideal for performance comfort.",
                nextRecommendation: "Pause extra calories and enter session hydrated.",
                tone: tone
            )
        }
    }

    func onTargetPreWorkoutContent(tone: SessionTone) -> SessionStateContent {
        switch tone {
        case .calm, .recovery:
            return SessionStateContent(
                title: "Pre-Workout On Target",
                message: "Your pre-session fueling looks well balanced.",
                nextRecommendation: "Maintain hydration and begin on schedule.",
                tone: tone
            )
        case .focused:
            return SessionStateContent(
                title: "Ready To Train",
                message: "Pre-workout nutrition is in a strong range.",
                nextRecommendation: "Hold this rhythm and move into session start.",
                tone: tone
            )
        case .assertive:
            return SessionStateContent(
                title: "Locked In",
                message: "Pre-workout setup is strong for performance.",
                nextRecommendation: "Start training with intent and keep execution tight.",
                tone: tone
            )
        }
    }

    func hydratedAndFueledContent(tone: SessionTone) -> SessionStateContent {
        switch tone {
        case .calm, .recovery:
            return SessionStateContent(
                title: "Steady In Session",
                message: "Fuel and hydration look stable right now.",
                nextRecommendation: "Maintain pace and keep sipping fluids.",
                tone: tone
            )
        case .focused:
            return SessionStateContent(
                title: "Fueling Looks Good",
                message: "You are holding a solid in-workout nutrition rhythm.",
                nextRecommendation: "Stay consistent and finish your planned work.",
                tone: tone
            )
        case .assertive:
            return SessionStateContent(
                title: "Good Mid-Session Support",
                message: "Fueling is supporting output well.",
                nextRecommendation: "Keep intensity high and maintain hydration.",
                tone: tone
            )
        }
    }

    func needRecoveryMealContent(tone: SessionTone) -> SessionStateContent {
        switch tone {
        case .calm, .recovery:
            return SessionStateContent(
                title: "Recovery Meal Needed",
                message: "Post-workout intake is still very light.",
                nextRecommendation: "Add an easy recovery meal now.",
                tone: tone
            )
        case .focused:
            return SessionStateContent(
                title: "Time To Recover",
                message: "You are in the recovery window without enough nutrition.",
                nextRecommendation: "Log a carb + protein recovery meal now.",
                tone: tone
            )
        case .assertive:
            return SessionStateContent(
                title: "Recover Immediately",
                message: "Your session is done and recovery fuel is missing.",
                nextRecommendation: "Refuel now with protein and carbs.",
                tone: tone
            )
        }
    }

    func lowProteinRecoveryContent(tone: SessionTone) -> SessionStateContent {
        switch tone {
        case .calm, .recovery:
            return SessionStateContent(
                title: "Protein Recovery Low",
                message: "Protein intake is still behind for repair support.",
                nextRecommendation: "Add a protein-focused meal or shake next.",
                tone: tone
            )
        case .focused:
            return SessionStateContent(
                title: "Protein Top-Up Needed",
                message: "Recovery protein is below your target range.",
                nextRecommendation: "Prioritize 20-35g protein in your next intake.",
                tone: tone
            )
        case .assertive:
            return SessionStateContent(
                title: "Protein Gap After Session",
                message: "Recovery protein is too low for this workload.",
                nextRecommendation: "Add protein now and close the recovery gap.",
                tone: tone
            )
        }
    }

    func lowCarbRecoveryContent(tone: SessionTone) -> SessionStateContent {
        switch tone {
        case .calm, .recovery:
            return SessionStateContent(
                title: "Carb Refill Needed",
                message: "Carb recovery is still under target.",
                nextRecommendation: "Add a moderate carb source in your next meal.",
                tone: tone
            )
        case .focused:
            return SessionStateContent(
                title: "Replenish Carbs",
                message: "Glycogen recovery is lagging after training.",
                nextRecommendation: "Add 30-50g carbs in your next recovery intake.",
                tone: tone
            )
        case .assertive:
            return SessionStateContent(
                title: "Carb Recovery Lagging",
                message: "Post-session carbs are below your recovery demand.",
                nextRecommendation: "Refill carbs now to restore training readiness.",
                tone: tone
            )
        }
    }

    func recoveryOnTrackContent(tone: SessionTone) -> SessionStateContent {
        switch tone {
        case .calm, .recovery:
            return SessionStateContent(
                title: "Recovery On Track",
                message: "Post-workout intake is in a healthy range.",
                nextRecommendation: "Continue steady meals through the support phase.",
                tone: tone
            )
        case .focused:
            return SessionStateContent(
                title: "Strong Recovery Flow",
                message: "You are recovering well from this session.",
                nextRecommendation: "Maintain this rhythm into later meals.",
                tone: tone
            )
        case .assertive:
            return SessionStateContent(
                title: "Recovery Locked In",
                message: "Post-workout fueling is supporting adaptation well.",
                nextRecommendation: "Keep consistency high through the evening window.",
                tone: tone
            )
        }
    }

    func underFueledSupportContent(tone: SessionTone) -> SessionStateContent {
        switch tone {
        case .calm, .recovery:
            return SessionStateContent(
                title: "Support Fuel Is Low",
                message: "You still have a meaningful fuel gap for today.",
                nextRecommendation: "Add a balanced meal and keep hydration steady.",
                tone: tone
            )
        case .focused:
            return SessionStateContent(
                title: "Close The Day Gap",
                message: "Overall intake is still below where it should be.",
                nextRecommendation: "Prioritize one structured meal with carbs + protein.",
                tone: tone
            )
        case .assertive:
            return SessionStateContent(
                title: "Targets Falling Behind",
                message: "You are under target late in the training-day window.",
                nextRecommendation: "Refuel now and close calories decisively.",
                tone: tone
            )
        }
    }

    func onTargetSupportContent(tone: SessionTone) -> SessionStateContent {
        switch tone {
        case .calm, .recovery:
            return SessionStateContent(
                title: "Support Is On Target",
                message: "Your support-phase intake is in a healthy range.",
                nextRecommendation: "Keep portions steady and finish the day cleanly.",
                tone: tone
            )
        case .focused:
            return SessionStateContent(
                title: "Good Support Rhythm",
                message: "You are pacing daily intake well in this phase.",
                nextRecommendation: "Maintain balanced meals and avoid unnecessary extras.",
                tone: tone
            )
        case .assertive:
            return SessionStateContent(
                title: "Targets In Control",
                message: "Support-phase fueling is aligned with your plan.",
                nextRecommendation: "Stay disciplined and close out with consistency.",
                tone: tone
            )
        }
    }

    func overFueledSupportContent(tone: SessionTone) -> SessionStateContent {
        switch tone {
        case .calm, .recovery:
            return SessionStateContent(
                title: "Support Intake Is High",
                message: "You are above planned support-phase intake.",
                nextRecommendation: "Keep the next meal lighter and focus on hydration.",
                tone: tone
            )
        case .focused:
            return SessionStateContent(
                title: "Above Support Targets",
                message: "Current intake has moved beyond your planned range.",
                nextRecommendation: "Shift to lean protein and low-fat choices for the next meal.",
                tone: tone
            )
        case .assertive:
            return SessionStateContent(
                title: "Overshoot In Support",
                message: "You have exceeded support-phase needs.",
                nextRecommendation: "Pause extra calories and rebalance your next intake.",
                tone: tone
            )
        }
    }

    func underFueledScheduledContent(tone: SessionTone) -> SessionStateContent {
        switch tone {
        case .calm, .recovery:
            return SessionStateContent(
                title: "Fuel Is Low",
                message: "Your intake is still very light for a training day.",
                nextRecommendation: "Start with an easy meal and hydrate.",
                tone: tone
            )
        case .focused:
            return SessionStateContent(
                title: "Underfueled Start",
                message: "You are behind on early fuel heading into training.",
                nextRecommendation: "Log a balanced meal now: carbs + protein.",
                tone: tone
            )
        case .assertive:
            return SessionStateContent(
                title: "Refuel Now",
                message: "Current intake is too low for session demand.",
                nextRecommendation: "Add fuel immediately: fast carbs plus protein.",
                tone: tone
            )
        }
    }

    func onTargetScheduledContent(tone: SessionTone) -> SessionStateContent {
        switch tone {
        case .calm, .recovery:
            return SessionStateContent(
                title: "Prep Is On Track",
                message: "Your early fueling pattern looks steady.",
                nextRecommendation: "Keep the same rhythm into pre-workout.",
                tone: tone
            )
        case .focused:
            return SessionStateContent(
                title: "Good Prep Rhythm",
                message: "You are tracking well for this session window.",
                nextRecommendation: "Maintain timing and add your next planned pre meal.",
                tone: tone
            )
        case .assertive:
            return SessionStateContent(
                title: "Ready And Building",
                message: "Fuel setup is solid so far.",
                nextRecommendation: "Stay consistent and complete your pre-workout intake.",
                tone: tone
            )
        }
    }

    func overFueledScheduledContent(tone: SessionTone) -> SessionStateContent {
        switch tone {
        case .calm, .recovery:
            return SessionStateContent(
                title: "Fuel Is Running High",
                message: "You are already above planned intake for this point of the day.",
                nextRecommendation: "Keep the next meal lighter and protein-forward.",
                tone: tone
            )
        case .focused:
            return SessionStateContent(
                title: "Above Scheduled Targets",
                message: "Current intake has moved beyond planned scheduled-phase targets.",
                nextRecommendation: "Shift next intake to lean protein and hydration only.",
                tone: tone
            )
        case .assertive:
            return SessionStateContent(
                title: "Overshoot Detected",
                message: "You have exceeded scheduled fueling needs.",
                nextRecommendation: "Pause extra calories and rebalance with low-fat, high-protein choices.",
                tone: tone
            )
        }
    }

    func fallbackContent(dayMode: DayMode, tone: SessionTone) -> SessionStateContent {
        switch dayMode {
        case .rest:
            return SessionStateContent(
                title: "Rest Day",
                message: "Keep intake steady and focus on consistency.",
                nextRecommendation: "Hit your daily protein target and hydrate.",
                tone: tone
            )
        case .training(let phase):
            return SessionStateContent(
                title: phaseFallbackTitle(phase),
                message: "State mapping for this phase is being tuned.",
                nextRecommendation: "Keep logging meals; guidance will adapt as we expand rules.",
                tone: tone
            )
        }
    }

    func phaseFallbackTitle(_ phase: TrainingPhase) -> String {
        switch phase {
        case .scheduled:
            return "Scheduled"
        case .preWorkout:
            return "Pre-Workout"
        case .inWorkout:
            return "In-Workout"
        case .postWorkout:
            return "Post-Workout"
        case .support:
            return "Support"
        }
    }
}
