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

struct ExerciseEstimate: Codable, Equatable, Hashable, Sendable {
    var activityType: String
    var durationMinutes: Int
    var intensity: String
}

struct LogEntryFeedback: Codable, Equatable, Hashable, Sendable {
    var explanation: String
    var assumptions: [String]
    var confidence: Double?
    var estimatedCalories: Double?
    var macros: Macros?
    var goalFitScore: Int?
    var goalType: GoalType? = nil
    var estimatedItems: [EstimatedItem]?
    var exercise: ExerciseEstimate? = nil
}
