//
//  LogEntryFeedback.swift
//  GymFuel
//
//  Created by Ahmad on 15/04/2026.
//

import Foundation

struct EstimatedItemComponent: Codable, Equatable, Hashable, Sendable {
    var name: String
    var estimatedAmount: String
}

struct EstimatedItem: Codable, Equatable, Hashable, Sendable {
    var name: String
    var quantity: String
    var estimatedComponents: [EstimatedItemComponent]
}

struct LogEntryFeedback: Codable, Equatable, Hashable, Sendable {
    var explanation: String
    var assumptions: [String]
    var confidence: Double?
    var macros: Macros?
    var goalFitScore: Int?
    var goalType: GoalType? = nil
    var estimatedItems: [EstimatedItem]?
    /// The editable tree — `meal-contract.md`. `nil` until Step 6 sends one, and
    /// again after a manual total override. A meal without one shows its totals
    /// and never gains invented component detail.
    @Lenient var breakdown: MealBreakdown? = nil
    /// Where `macros` came from. `nil` reads as `.estimated`.
    var macrosProvenance: MealProvenance? = nil
}
