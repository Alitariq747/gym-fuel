//
//  CheckInSchedule.swift
//  GymFuel
//

import Foundation

/// When a weekly check-in is due (decision 3).
///
/// Pure, like `PaceCheckCalculator`, and on date keys rather than timestamps. A
/// check-in falls due every 7 days from the day the current phase started. Only
/// the current phase and the newest check-in are read — never the whole
/// collection — so Steps 12 and 14 can ask for `nextDueDateKey` cheaply.
struct CheckInSchedule {
    static let intervalDays = 7

    let phase: Phase
    /// The most recently completed check-in, from any phase.
    let latest: CheckIn?
    let todayKey: String
    var timeZone: TimeZone = .current

    /// The latest `start + 7k` on or before today, for k ≥ 1. Missed weeks
    /// collapse into this one.
    var latestDueDateKey: String? {
        guard let k = weeksElapsed, k >= 1 else { return nil }
        return key(weeksAfterStart: k)
    }

    /// The check-in waiting to be answered, or `nil`.
    ///
    /// A record only counts if it belongs to **this** phase: a new phase's due
    /// dates start again from its own first day.
    var openDueDateKey: String? {
        guard let due = latestDueDateKey else { return nil }
        if let latest,
           latest.phaseStartDateKey == phase.startDateKey,
           latest.dueDateKey >= due {
            return nil
        }
        return due
    }

    /// The open check-in if there is one, otherwise the next one to fall due.
    var nextDueDateKey: String? {
        if let open = openDueDateKey { return open }
        guard let k = weeksElapsed else { return nil }
        return key(weeksAfterStart: max(k, 0) + 1)
    }

    // MARK: - Private

    /// Whole weeks from the phase start to today, or `nil` for a malformed key.
    private var weeksElapsed: Int? {
        guard let start = DateKey.date(from: phase.startDateKey, timeZone: timeZone),
              let today = DateKey.date(from: todayKey, timeZone: timeZone),
              let days = DateKey.calendar(timeZone: timeZone).dateComponents([.day], from: start, to: today).day
        else { return nil }
        return days < 0 ? -1 : days / Self.intervalDays
    }

    private func key(weeksAfterStart weeks: Int) -> String? {
        guard let start = DateKey.date(from: phase.startDateKey, timeZone: timeZone),
              let due = DateKey.calendar(timeZone: timeZone)
                .date(byAdding: .day, value: weeks * Self.intervalDays, to: start)
        else { return nil }
        return DateKey.key(for: due, timeZone: timeZone)
    }
}
