//
//  TrainingExperience.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//



import Foundation

/// Rough estimate of how adapted the user is to training.
/// This helps us decide how aggressive we can be with deficits/surpluses.

enum TrainingExperience: String, CaseIterable, Codable {
    case beginner = "beginner"        // ~0–6 months
    case intermediate = "intermediate"// ~6–24 months
    case advanced = "advanced"        // 2+ years
    
    var displayName: String {
        switch self {
        case .beginner:
            return "Beginner (0–6 months)"
        case .intermediate:
            return "Intermediate (6–24 months)"
        case .advanced:
            return "Advanced (2+ years)"
        }
    }
    
    var detail: String {
        switch self {
        case .beginner:
            return "You’re still new to training and need progress."
        case .intermediate:
            return "You’ve been training consistently for a while."
        case .advanced:
            return "You’re highly trained and progress is slower."
        }
    }
}
