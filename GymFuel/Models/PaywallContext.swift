//
//  PaywallContext.swift
//  GymFuel
//

import Foundation

/// What the paywall straight after onboarding says about the person's own plan
/// and meal (build-order 15e). In-app paywalls have none.
struct PaywallContext: Equatable {
    struct Meal: Equatable {
        let title: String
        let kcal: Double
        let edited: Bool

        /// Never "saved": the tried meal is not saved (build-order 15c).
        var line: String {
            edited
                ? "You changed what it assumed, and the total followed. Every meal works like this."
                : "It shows what it assumed, and every amount is yours to change."
        }
    }

    let calories: Double
    let planLine: String?
    let subtitle: String?
    let meal: Meal?

    init?(profile: UserProfile, answers: OnboardingAnswers, unit: BodyWeightUnit) {
        guard let targets = profile.savedTargets else { return nil }

        calories = targets.calories
        planLine = WeightPlan(profile: profile).map { PlanCopy.headline(for: $0, unit: unit) }
        subtitle = answers.loggingProblem?.paywallSubtitle
        meal = answers.triedMeal.flatMap { tried in
            tried.feedback.breakdown.map { breakdown in
                let calculator = MealBreakdownCalculator()
                return Meal(
                    title: tried.title,
                    kcal: calculator.total(of: breakdown).calories,
                    edited: !calculator.adjustedParts(of: breakdown).isEmpty
                )
            }
        }
    }
}
