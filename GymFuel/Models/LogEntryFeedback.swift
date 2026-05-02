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
    var estimatedCalories: Double?
    var macros: Macros?
    var goalFitScore: Int?
    var rebalanceHint: String?
}
