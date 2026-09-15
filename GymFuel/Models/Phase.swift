//
//  Phase.swift
//  GymFuel
//

import Foundation

/// One stretch of a goal and pace, from the day it started.
///
/// `startDateKey` **is** the Firestore document ID (`"yyyy-MM-dd"`), like
/// `WeighIn.dateKey`. A phase is history: the goal, pace, weight and targets the
/// stretch started with. The one number that moves while it runs is
/// `calorieAdjustment` — the sum of the steps the weekly check-in has made.
/// Today's target is still worked out live as `formula + calorieAdjustment`;
/// `startTargets` is never read for today.
struct Phase: Identifiable, Equatable, Sendable {
    let startDateKey: String
    let goalType: GoalType
    /// `nil` for Maintain.
    let goalPace: GoalPace?
    /// A magnitude — the sign comes from `goalType`. See "The sign still matters"
    /// in `build-order.md`.
    let pacePercentPerWeek: Double
    let startWeightKg: Double
    /// Copied from the profile. Changing it updates this phase in place rather
    /// than starting a new one, so it cannot reset the check-in wait.
    var targetWeightKg: Double?
    /// Calories, protein, carbs and fat on the day the phase started.
    let startTargets: Macros
    /// Carried into the next phase when goal or pace changes.
    var calorieAdjustment: Double
    /// The day the user last accepted or rejected a suggested step.
    var lastStepDecisionDateKey: String?
    /// The instant the phase was started. Orders phases — see
    /// `FirebasePhaseService.fetchCurrentPhase`.
    let startedAt: Date

    var id: String { startDateKey }

    /// The goal pace in kilograms a week, at the weight the user had when they
    /// picked it. **Signed: negative means losing.** 0 for Maintain.
    var goalKgPerWeek: Double {
        guard let goalPace else { return 0 }
        return goalPace.kgPerWeek(for: goalType, weightKg: startWeightKg)
    }
}
