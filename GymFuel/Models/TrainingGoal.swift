//
//  TrainingGoal.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//


import Foundation

/// Long-term goal that shapes how we fuel the user overall.
enum TrainingGoal: String, CaseIterable, Codable {
    /// Slight deficit, protect performance and strength.
    case fatLoss = "fat_loss"
    
    /// Maintain weight, maximize performance & recovery.
    case performance = "performance"
    
    /// Small surplus, focus on muscle & strength gain.
    case muscleGain = "muscle_gain"
    
    /// User cares primarily about crushing workouts,
    /// bodyweight is secondary.
    case crushWorkouts = "crush_workouts"
    
    var displayName: String {
        switch self {
        case .fatLoss:
            return "Lose fat, keep strength"
        case .performance:
            return "Perform & recover"
        case .muscleGain:
            return "Build muscle & strength"
        case .crushWorkouts:
            return "Crush workouts"
        }
    }
    
    var detail: String {
        switch self {
        case .fatLoss:
            return "Slight calorie deficit while protecting strength and gym performance."
        case .performance:
            return "Stay around your current weight while fueling hard training and recovery."
        case .muscleGain:
            return "Small surplus to support muscle and strength gains over time."
        case .crushWorkouts:
            return "Fuel hard sessions first, bodyweight changes are secondary."
        }
    }
}
