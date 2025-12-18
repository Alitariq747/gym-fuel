//
//  MealTimingTag.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 11/12/2025.
//

import Foundation
import SwiftUI

enum MealTimingTag: String, Codable, CaseIterable {

    case preWorkout
    
    case postWorkout
    
    case otherOnTrainingDay
    
    case restDay
}

extension MealTimingTag {
    var emoji: String {
        switch self {
        case .preWorkout:         return "⚡️"
        case .postWorkout:        return "💪"
        case .otherOnTrainingDay: return "🍽️"
        case .restDay:            return "😴"
        }
    }

    var title: String {
        switch self {
        case .preWorkout:         return "Pre-workout"
        case .postWorkout:        return "Post-workout"
        case .otherOnTrainingDay: return "Other meals"
        case .restDay:            return "Rest day"
        }
    }

    var chipText: String {
        switch self {
        case .preWorkout:         return "Pre"
        case .postWorkout:        return "Post"
        case .otherOnTrainingDay: return "Other"
        case .restDay:            return "Rest"
        }
    }

    var color: Color {
        switch self {
        case .preWorkout:         return .blue
        case .postWorkout:        return .green
        case .otherOnTrainingDay: return .indigo
        case .restDay:            return .pink
        }
    }
}
