//
//  ActivityLevel.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 11/12/2025.
//



import Foundation

/// What a normal week looks like, including exercise.
/// Picks the multiplier on resting energy.

enum ActivityLevel: String, CaseIterable, Codable {
    case mostlySitting = "mostly_sitting"
    case lightlyActive = "lightly_active"
    case active = "active"
    case veryActive = "very_active"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = ActivityLevel(rawValue: rawValue) ?? .mostlySitting
    }

    var displayName: String {
        switch self {
        case .mostlySitting:
            return "Mostly sitting"
        case .lightlyActive:
            return "Lightly active"
        case .active:
            return "Active"
        case .veryActive:
            return "Very active"
        }
    }

    var detail: String {
        switch self {
        case .mostlySitting:
            return "Desk or study most of the day, little or no exercise."
        case .lightlyActive:
            return "Mostly sitting, plus a daily walk or exercise a few times a week."
        case .active:
            return "On your feet most of the day, or hard exercise most days."
        case .veryActive:
            return "Physical work all day, or hard training every day."
        }
    }
}
