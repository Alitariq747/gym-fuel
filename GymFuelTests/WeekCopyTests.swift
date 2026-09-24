//
//  WeekCopyTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// Like `TargetsCopyTests`, these avoid whole formatted strings: the weekday and
/// month names come from the device locale, so "Mon 1 – Sun 7 Sep" is only the
/// English form. What is worth pinning is which of the three titles is chosen,
/// and that the month is printed twice only when the week actually crosses one.
@Suite("WeekCopy")
struct WeekCopyTests {

    /// Monday-first and fixed, so the suite does not depend on where it runs.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        calendar.firstWeekday = 2
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }

    private func weekStart(containing date: Date) throws -> Date {
        try #require(calendar.dateInterval(of: .weekOfYear, for: date)?.start)
    }

    @Test("The week holding today is This week")
    func currentWeek() throws {
        let now = try date(2026, 9, 10)
        let start = try weekStart(containing: now)

        #expect(WeekCopy.title(weekStart: start, calendar: calendar, now: now) == "This week")
    }

    @Test("The week before it is Last week")
    func previousWeek() throws {
        let now = try date(2026, 9, 10)
        let start = try weekStart(containing: try date(2026, 9, 3))

        #expect(WeekCopy.title(weekStart: start, calendar: calendar, now: now) == "Last week")
    }

    @Test("Anything older is named by its own date")
    func olderWeek() throws {
        let now = try date(2026, 9, 10)
        let start = try weekStart(containing: try date(2026, 8, 26))
        let title = WeekCopy.title(weekStart: start, calendar: calendar, now: now)

        #expect(title.hasPrefix("Week of "))
        #expect(title != "This week")
        #expect(title != "Last week")
    }

    @Test("A week inside one month names that month once")
    func rangeWithinAMonth() throws {
        let start = try weekStart(containing: try date(2026, 9, 10))
        let range = WeekCopy.range(weekStart: start, calendar: calendar)
        let month = start.formatted(.dateTime.month(.abbreviated))

        #expect(range.components(separatedBy: month).count - 1 == 1)
    }

    @Test("A week crossing a month names both")
    func rangeAcrossMonths() throws {
        // Mon 31 Aug – Sun 6 Sep 2026.
        let start = try weekStart(containing: try date(2026, 9, 2))
        let end = try #require(calendar.date(byAdding: .day, value: 6, to: start))
        let range = WeekCopy.range(weekStart: start, calendar: calendar)

        #expect(range.contains(start.formatted(.dateTime.month(.abbreviated))))
        #expect(range.contains(end.formatted(.dateTime.month(.abbreviated))))
    }
}
