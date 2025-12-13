//
//  TrainingTimeOfDay.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 11/12/2025.
//



import Foundation

/// The time of day the user *usually* trains.
/// We use this to bias meal timing around their sessions.
enum TrainingTimeOfDay: String, CaseIterable, Codable {
    case morning = "morning"
    case midday = "midday"
    case evening = "evening"
    case varies = "varies"     
    
    var displayName: String {
        switch self {
        case .morning:
            return "Morning"
        case .midday:
            return "Midday / Lunch"
        case .evening:
            return "Evening"
        case .varies:
            return "It depends / varies"
        }
    }
    
    var detail: String {
        switch self {
        case .morning:
            return "You usually train in the morning, before starting your day."
        case .midday:
            return "You usually train around midday or early afternoon."
        case .evening:
            return "You usually train later in the day or at night."
        case .varies:
            return "Your training time changes often."
        }
    }
}
