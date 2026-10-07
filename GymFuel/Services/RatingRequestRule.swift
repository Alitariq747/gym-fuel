//
//  RatingRequestRule.swift
//  GymFuel
//

import Foundation

/// When to ask iOS for a rating: the first meal someone saves after correcting
/// its amounts, once per install. Never during onboarding (build-order 15c).
enum RatingRequestRule {
    static let requestedKey = "ratingRequested"

    static func shouldRequest(saving meal: SavedMeal, alreadyRequested: Bool) -> Bool {
        guard !alreadyRequested, let breakdown = meal.breakdown else { return false }
        return !MealBreakdownCalculator().adjustedParts(of: breakdown).isEmpty
    }
}
