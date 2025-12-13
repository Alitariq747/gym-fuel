//
//  TrainingStyle.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//



import Foundation

/// User's primary training style, used to bias fueling (e.g. more carbs for endurance).
enum TrainingStyle: String, CaseIterable, Codable {
    case strength = "strength"
    case hypertrophy = "hypertrophy"
    case mixed = "mixed"
    case endurance = "endurance"       
    
    var displayName: String {
        switch self {
        case .strength:
            return "Strength / Power"
        case .hypertrophy:
            return "Bodybuilding / Hypertrophy"
        case .mixed:
            return "Mixed / CrossFit / HIIT"
        case .endurance:
            return "Endurance (running, cycling, etc.)"
        }
    }
    
    var detail: String {
        switch self {
        case .strength:
            return "Heavy lifting, low to moderate reps, focus on maximal strength."
        case .hypertrophy:
            return "Training mainly to build muscle size and shape."
        case .mixed:
            return "Blends strength work with conditioning, circuits, or CrossFit-style sessions."
        case .endurance:
            return "Longer runs, rides, or similar cardio-focused training."
        }
    }
}

