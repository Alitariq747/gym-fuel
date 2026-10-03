//
//  TodaySnapshot+Entries.swift
//  GymFuel
//
//  App target only — the widget never sees a `LogEntry`.
//

import Foundation

extension TodaySnapshot {
    /// `eaten` is the Day card's own total, passed in rather than summed again.
    /// The count and the dotted rule look at the same entries that total sums.
    init(day: Date, target: Macros, eaten: Macros, entries: [LogEntry], calendar: Calendar = .current) {
        let settled = entries.compactMap(\.feedback).filter { $0.macros != nil }
        let calculator = MealBreakdownCalculator()

        self.init(
            day: calendar.startOfDay(for: day),
            target: target,
            eaten: eaten,
            loggedCount: settled.count,
            hasEstimate: settled.contains { calculator.provenance(of: $0) == .estimated }
        )
    }

    /// `nil` leaves the widget's note as it is. A placeholder day — before the
    /// entries arrive, or after a failed load — must never overwrite a real one.
    init?(today timeline: DayTimeline, isLoaded: Bool, target: Macros?, eaten: Macros,
          now: Date = .now, calendar: Calendar = .current) {
        guard isLoaded, let target, calendar.isDate(timeline.date, inSameDayAs: now) else { return nil }
        self.init(day: timeline.date, target: target, eaten: eaten, entries: timeline.entries, calendar: calendar)
    }
}
