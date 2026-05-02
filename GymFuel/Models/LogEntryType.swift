//
//  LogEntryType.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/04/2026.
//

import Foundation

enum LogEntryType: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case food
    case exercise

    var displayName: String {
        switch self {
        case .food:
            return "Meal"
        case .exercise:
            return "Exercise"
        }
    }
}
