//
//  LogEntryFeedback.swift
//  GymFuel
//
//  Created by Ahmad on 15/04/2026.
//

import Foundation

struct LogEntryFeedback: Codable, Equatable, Hashable, Sendable {
    var explanation: String
    var assumptions: [String]
    var confidence: Double?
    var macros: Macros?
    /// The editable tree — `meal-contract.md`. `nil` when the model could price
    /// nothing, and again after a manual total override. A meal without one shows
    /// its totals and never gains invented component detail.
    @Lenient var breakdown: MealBreakdown? = nil
    /// Where `macros` came from. `nil` reads as `.estimated`.
    var macrosProvenance: MealProvenance? = nil
}
