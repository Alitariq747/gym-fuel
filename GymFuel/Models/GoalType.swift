//
//  GoalType.swift
//  GymFuel
//
//  Created by Ahmad on 05/03/2026.
//

import Foundation

enum GoalType: String, CaseIterable, Codable, Equatable {
    case leanBulk = "lean_bulk"
    case maintain = "maintain"
    case cut = "cut"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = GoalType(rawValue: rawValue) ?? .maintain
    }

    var displayName: String {
        switch self {
        case .leanBulk:
            return "Gain"
        case .maintain:
            return "Maintain"
        case .cut:
            return "Lose fat"
        }
    }

    var detail: String {
        switch self {
        case .leanBulk:
            return "Gain weight steadily on a controlled calorie surplus, so it goes on gradually rather than all at once."
        case .maintain:
            return "Stay around your current weight, with nutrition balanced enough to keep your energy steady day to day."
        case .cut:
            return "Lose weight with tighter calorie control, keeping protein high enough that most of what you lose is fat."
        }
    }

    var symbolName: String {
        switch self {
        case .leanBulk:
            return "arrow.up.right"
        case .maintain:
            return "arrow.left.and.right"
        case .cut:
            return "arrow.down.right"
        }
    }
}

extension GoalType {
    static let defaultValue: GoalType = .maintain
}
