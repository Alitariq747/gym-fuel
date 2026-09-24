//
//  StatsCalculatorTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// The averages are over the days that have food, not over seven. A week logged
/// on four days out of seven used to report roughly four sevenths of what was
/// eaten, which is a number nobody ate.
@Suite("StatsCalculator")
struct StatsCalculatorTests {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        calendar.firstWeekday = 2
        return calendar
    }

    private let targets = Macros(calories: 2400, protein: 165, carbs: 240, fat: 80)

    private func weekStart() throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 7)))
    }

    private func entry(dayOffset: Int, calories: Double, from start: Date) throws -> LogEntry {
        let loggedAt = try #require(calendar.date(byAdding: .day, value: dayOffset, to: start))
        return LogEntry(
            userId: "u",
            loggedAt: loggedAt,
            title: "meal",
            rawInput: "meal",
            feedback: LogEntryFeedback(
                explanation: "",
                macros: Macros(calories: calories, protein: 40, carbs: 60, fat: 20)
            )
        )
    }

    private func snapshot(_ calories: [Double]) throws -> StatsSnapshot {
        let start = try weekStart()
        let entries = try calories.enumerated().map { try entry(dayOffset: $0.offset, calories: $0.element, from: start) }
        return StatsCalculator().calculate(
            weeklyEntries: entries,
            currentStreakEntries: entries,
            targetMacros: targets,
            selectedWeekStart: start,
            calendar: calendar
        )
    }

    @Test("Averages divide by the days with food, not by seven")
    func averageOverLoggedDays() throws {
        let week = try snapshot([2400, 2400, 2400, 2400])

        #expect(week.daysWithFood == 4)
        #expect(week.averageCalories == 2400)
        #expect(week.averageProtein == 40)
    }

    @Test("A full week still averages over seven days")
    func fullWeekUnchanged() throws {
        let week = try snapshot([2100, 2200, 2300, 2400, 2500, 2600, 2700])

        #expect(week.daysWithFood == 7)
        #expect(week.averageCalories == 2400)
    }

    @Test("A week with nothing logged averages zero rather than dividing by zero")
    func emptyWeekDoesNotDivideByZero() throws {
        let start = try weekStart()
        let week = StatsCalculator().calculate(
            weeklyEntries: [],
            currentStreakEntries: [],
            targetMacros: targets,
            selectedWeekStart: start,
            calendar: calendar
        )

        #expect(week.averageCalories == 0)
        #expect(week.averageProtein == 0)
        #expect(week.dailyStats.count == 7)
    }

    @Test("The streak survives the Week screen losing its tile")
    func streakStillComputed() throws {
        // Step 12 reads this; 7t removed only the card that displayed it.
        let week = try snapshot([2400, 2400])

        #expect(week.foodLogsThisWeek == 2)
        #expect(week.daysLoggedThisWeek == 2)
    }
}
