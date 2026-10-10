//
//  LoggingProblem.swift
//  GymFuel
//

import Foundation

/// The onboarding answer to "What makes logging food hard for you?", and every
/// line that answer changes later (build-order 15d).
enum LoggingProblem: String, CaseIterable {
    // Raw values are the analytics names.
    case notInDatabase = "not_in_database"
    case unknownPortions = "unknown_portions"
    case tooSlow = "too_slow"
    case neverTracked = "never_tracked"

    /// The try-meal line with no answer, which only previews reach.
    static let defaultTryMealDetail = "Say it the way you'd tell a friend."

    var title: String {
        switch self {
        case .notInDatabase: "My food isn't in any database"
        case .unknownPortions: "I never know the portions or what went in"
        case .tooSlow: "Searching and weighing takes too long"
        case .neverTracked: "I've never tracked before"
        }
    }

    /// Under "Tell us a meal you often eat."
    var tryMealDetail: String {
        switch self {
        case .notInDatabase: "Pick one you couldn't find in an app. Say it the way you'd tell a friend."
        case .unknownPortions: "Rough is fine. Circa shows what it assumed, so you can change it."
        case .tooSlow: "One sentence. No searching, no weighing."
        case .neverTracked: "Nothing to look up. Say it the way you'd tell a friend."
        }
    }

    /// Above the targets on the plan screen.
    var planLine: String {
        switch self {
        case .notInDatabase: "Your own food works here: describe it, check what was assumed, fix what's different."
        case .unknownPortions: "Circa says what it assumed about portions and what went in. You fix what's different."
        case .tooSlow: "No searching, no weighing: describe it, check what was assumed, fix what's different."
        case .neverTracked: "Each meal is one sentence: describe it, check what was assumed, fix what's different."
        }
    }

    /// Under the plan on the paywall after onboarding (build-order 15e).
    var paywallSubtitle: String {
        switch self {
        case .notInDatabase: "Built for the food databases miss: home-cooked, local, your own recipes."
        case .unknownPortions: "Every estimate shows the portions it assumed, so the guessing is out in the open."
        case .tooSlow: "One sentence a meal. No searching, no weighing."
        case .neverTracked: "Start with one meal, in your own words. Nothing to look up."
        }
    }
}
