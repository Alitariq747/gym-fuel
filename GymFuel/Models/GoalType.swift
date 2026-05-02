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

    var displayName: String {
        switch self {
        case .leanBulk:
            return "Lean Bulk"
        case .maintain:
            return "Maintain"
        case .cut:
            return "Cut"
        }
    }

    var detail: String {
        switch self {
        case .leanBulk:
            return "Build muscle with a controlled calorie surplus, so weight gain stays more intentional and not excessively fast."
        case .maintain:
            return "Stay around your current body weight while keeping nutrition balanced enough to support recovery, performance, and consistency."
        case .cut:
            return "Lose fat with tighter calorie control while still keeping nutrition strong enough to support recovery and muscle retention."
        }
    }
}

extension GoalType {
    static let defaultValue: GoalType = .maintain
}
