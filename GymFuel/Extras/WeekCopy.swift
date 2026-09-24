//
//  WeekCopy.swift
//  GymFuel
//

import Foundation

/// How the Week screen names the week it is showing. Pure: no UI, no Firebase.
///
/// The title and the range are two strings rather than one sentence because the
/// `Week` artboard sets them in different faces — the title in SF Pro, the range
/// in mono — so the header renders them separately.
enum WeekCopy {

    /// "This week", "Last week", or the week's own date for anything older.
    static func title(weekStart: Date, calendar: Calendar = .current, now: Date = .now) -> String {
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start
            ?? calendar.startOfDay(for: now)

        if calendar.isDate(weekStart, inSameDayAs: currentWeekStart) {
            return "This week"
        }
        if let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart),
           calendar.isDate(weekStart, inSameDayAs: lastWeekStart) {
            return "Last week"
        }
        return "Week of \(weekStart.formatted(.dateTime.day().month(.abbreviated)))"
    }

    /// "Mon 1 – Sun 7 Sep". The month appears on the first date only when the
    /// week crosses one, so the common case stays short. The header uppercases it.
    static func range(weekStart: Date, calendar: Calendar = .current) -> String {
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return weekStart.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        }

        let crossesMonth = !calendar.isDate(weekStart, equalTo: weekEnd, toGranularity: .month)
        let start = crossesMonth
            ? weekStart.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
            : weekStart.formatted(.dateTime.weekday(.abbreviated).day())
        let end = weekEnd.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        return "\(start) – \(end)"
    }
}
