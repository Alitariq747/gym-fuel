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
    
    var detail: String {
        switch self {
        case .mostlySitting:
            return "Desk job or student, lots of sitting, little movement outside workouts."
        case .somewhatActive:
            return "On your feet a fair bit (teaching, retail, walking around), but not heavy physical labor."
        case .physicallyDemanding:
            return "Job or daily life involves regular physical work (construction, warehouse, delivery, etc.)."
        }
    }
}
