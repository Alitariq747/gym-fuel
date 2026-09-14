//
//  GoalPace.swift
//  GymFuel
//



import Foundation

enum GoalPace: String, Codable, CaseIterable, Equatable {
    case slow
    case gentle
    case steady
    case faster

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = GoalPace(rawValue: rawValue) ?? .steady
    }

    var displayName: String {
        switch self {
        case .slow:
            return "Slow"
        case .gentle:
            return "Gentle"
        case .steady:
            return "Steady"
        case .faster:
            return "Faster"
        }
    }

    /// The paces a goal offers, slowest first. Maintain has none.
    static func options(for goal: GoalType) -> [GoalPace] {
        switch goal {
        case .cut:
            return [.gentle, .steady, .faster]
        case .leanBulk:
            return [.slow, .steady]
        case .maintain:
            return []
        }
    }

    /// The pace to actually use. Always read a stored pace through this: a
    /// profile save merges, so it can never clear a pace left over from an
    /// earlier goal.
    ///
    /// - Maintain → `nil`
    /// - missing, or not offered for this goal → `.steady`
    static func resolved(_ stored: GoalPace?, for goal: GoalType?) -> GoalPace? {
        let offered = options(for: goal ?? .defaultValue)
        guard !offered.isEmpty else { return nil }
        if let stored, offered.contains(stored) { return stored }
        return .steady
    }

    /// Percent of body weight a week, as a magnitude (0.75 means 0.75 %).
    /// A pace the goal does not offer is resolved first.
    func percentPerWeek(for goal: GoalType) -> Double {
        switch (goal, GoalPace.resolved(self, for: goal)) {
        case (.cut, .gentle?):
            return 0.5
        case (.cut, .steady?):
            return 0.75
        case (.cut, .faster?):
            return 1.0
        case (.leanBulk, .slow?):
            return 0.25
        case (.leanBulk, .steady?):
            return 0.5
        default:
            return 0
        }
    }

    /// Kilograms a week. Negative when losing.
    func kgPerWeek(for goal: GoalType, weightKg: Double) -> Double {
        let magnitude = weightKg * percentPerWeek(for: goal) / 100
        return goal == .cut ? -magnitude : magnitude
    }

    /// "about 0.6 kg a week", in the user's unit. Shown next to each pace.
    func aboutPerWeekText(for goal: GoalType, weightKg: Double, unit: BodyWeightUnit) -> String {
        let amount = BodyWeight.displayString(
            kilograms: abs(kgPerWeek(for: goal, weightKg: weightKg)),
            unit: unit
        )
        return "about \(amount) a week"
    }
}
