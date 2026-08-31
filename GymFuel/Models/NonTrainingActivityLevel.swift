//
//  NonTrainingActivityLevel.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 11/12/2025.
//



import Foundation

/// User's general activity level *outside* of training.
/// Used to adjust baseline TDEE, especially on rest days.

enum NonTrainingActivityLevel: String, CaseIterable, Codable {
    case mostlySitting = "mostly_sitting"
    case somewhatActive = "somewhat_active"
    case physicallyDemanding = "physically_demanding"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = NonTrainingActivityLevel(rawValue: rawValue) ?? .mostlySitting
    }

    var displayName: String {
        switch self {
        case .mostlySitting:
            return "Mostly sitting"
        case .somewhatActive:
            return "Moderately active"
        case .physicallyDemanding:
            return "Physically demanding"
        }
    }

    var shortDisplayName: String {
        switch self {
        case .mostlySitting:
            return "Sedentary"
        case .somewhatActive:
            return "Active"
        case .physicallyDemanding:
            return "Demanding"
        }
    }
    
    var detail: String {
        switch self {
        case .mostlySitting:
            return "Mostly desk or study time with light daily movement."
        case .somewhatActive:
            return "On your feet often, but not heavy physical labor."
        case .physicallyDemanding:
            return "Daily work includes lifting, carrying, or long active hours."
        }
    }
}
