//
//  TodaySnapshot.swift
//  GymFuel
//
//  Shared with the widget extension. Foundation only: no Firebase, no UI.
//

import Foundation

/// The note the app leaves for the widget, which only ever reads it —
/// `build-order.md` Step 14. No burn, streak or weight field (Steps 3 and 12).
struct TodaySnapshot: Codable, Equatable, Sendable {
    /// The start of the day these numbers describe.
    var day: Date
    var target: Macros
    /// Settled entries only. An unfinished meal is not counted, and not logged.
    var eaten: Macros
    var loggedCount: Int
    /// The dotted rule, `design.md` rule 1.
    var hasEstimate: Bool

    enum State: Equatable {
        case newDay, normal, over
    }

    var state: State {
        if loggedCount == 0 { return .newDay }
        return caloriesLeft < 0 ? .over : .normal
    }

    /// Negative when over. The Day card's sum, so the two never disagree.
    var caloriesLeft: Int {
        Int((target.calories - eaten.calories).rounded())
    }

    /// How full the Lock Screen's ring is: never below empty, never past full.
    var calorieProgress: Double {
        guard target.calories > 0 else { return 0 }
        return min(max(eaten.calories / target.calories, 0), 1)
    }

    /// Targets change only when the person acts, so an earlier day's target is
    /// still right: a new day starts with the whole target left.
    func rolledOver(to date: Date, calendar: Calendar = .current) -> TodaySnapshot {
        guard !calendar.isDate(day, inSameDayAs: date) else { return self }

        return TodaySnapshot(
            day: calendar.startOfDay(for: date),
            target: target,
            eaten: .zero,
            loggedCount: 0,
            hasEstimate: false
        )
    }

    static func nextMidnight(after date: Date, calendar: Calendar = .current) -> Date {
        let today = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(86_400)
    }
}
