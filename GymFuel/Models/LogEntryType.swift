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

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = LogEntryType(rawValue: rawValue) ?? .food
    }

    var displayName: String {
        switch self {
        case .food:
            return "Meal"
        case .exercise:
            return "Exercise"
        }
    }
}
