//
//  TrialTimelineTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import Circa

@Suite("TrialTimeline")
struct TrialTimelineTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)))
    }

    @Test("A three-day offer reads 3-day")
    func threeDays() {
        let trial = TrialTimeline(periodValue: 3, unit: .day, numberOfPeriods: 1)
        #expect(trial.count == 3)
        #expect(trial.lengthText == "3-day")
    }

    @Test("Repeated periods multiply into the length")
    func repeatedPeriods() {
        let trial = TrialTimeline(periodValue: 1, unit: .week, numberOfPeriods: 2)
        #expect(trial.count == 2)
        #expect(trial.lengthText == "2-week")
    }

    @Test("Each unit has its own word")
    func unitWords() {
        #expect(TrialTimeline(periodValue: 1, unit: .month, numberOfPeriods: 1).lengthText == "1-month")
        #expect(TrialTimeline(periodValue: 1, unit: .year, numberOfPeriods: 1).lengthText == "1-year")
    }

    @Test("Billing starts when a three-day trial ends")
    func billingAfterDays() throws {
        let trial = TrialTimeline(periodValue: 3, unit: .day, numberOfPeriods: 1)
        let start = try date(2026, 10, 8)
        let expected = try date(2026, 10, 11)
        #expect(trial.billingDate(from: start, calendar: calendar) == expected)
    }

    @Test("A week-long trial bills seven days later")
    func billingAfterWeek() throws {
        let trial = TrialTimeline(periodValue: 1, unit: .week, numberOfPeriods: 1)
        let start = try date(2026, 10, 8)
        let expected = try date(2026, 10, 15)
        #expect(trial.billingDate(from: start, calendar: calendar) == expected)
    }

    @Test("A month-long trial from 31 January bills on the last day of February")
    func billingAfterMonthEnd() throws {
        let trial = TrialTimeline(periodValue: 1, unit: .month, numberOfPeriods: 1)
        let start = try date(2027, 1, 31)
        let expected = try date(2027, 2, 28)
        #expect(trial.billingDate(from: start, calendar: calendar) == expected)
    }
}
