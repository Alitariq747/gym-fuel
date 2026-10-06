//
//  WeightChartRangeTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("WeightChartRange")
struct WeightChartRangeTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    /// 6 October 2026, 15:00 UTC.
    private let now = Date(timeIntervalSince1970: 1_791_298_800)

    private func day(_ month: Int, _ day: Int, hour: Int = 0) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour)))
    }

    private func domain(_ range: WeightChartRange, first: Date?) -> ClosedRange<Date> {
        range.domain(firstWeighIn: first, now: now, calendar: calendar)
    }

    @Test("The fixed date really is 6 October, mid-afternoon")
    func fixture() throws {
        #expect(now == (try day(10, 6, hour: 15)))
    }

    @Test("Every range runs through the end of today")
    func endsAfterToday() throws {
        for range in WeightChartRange.allCases {
            #expect(domain(range, first: try day(1, 1)).upperBound == (try day(10, 7)))
        }
    }

    @Test("30d and 90d count today as one of their days")
    func fullRanges() throws {
        let first = try day(1, 1, hour: 12)

        #expect(domain(.thirtyDays, first: first).lowerBound == (try day(9, 7)))
        #expect(domain(.ninetyDays, first: first).lowerBound == (try day(7, 9)))
    }

    @Test("All starts on the first weigh-in's day")
    func allStartsAtFirstWeighIn() throws {
        #expect(domain(.all, first: try day(3, 15, hour: 12)).lowerBound == (try day(3, 15)))
    }

    @Test("A range with no weigh-ins at its start begins at the first one")
    func trimsEmptyStart() throws {
        let first = try day(9, 20, hour: 12)

        #expect(domain(.ninetyDays, first: first).lowerBound == (try day(9, 20)))
        #expect(domain(.thirtyDays, first: first).lowerBound == (try day(9, 20)))
    }

    @Test("Never less than a week, so one weigh-in doesn't fill the width")
    func atLeastAWeek() throws {
        let weekBack = try day(9, 30)

        for range in WeightChartRange.allCases {
            #expect(domain(range, first: try day(10, 6, hour: 12)).lowerBound == weekBack)
            #expect(domain(range, first: nil).lowerBound <= weekBack)
        }
        #expect(domain(.all, first: nil).lowerBound == weekBack)
    }
}
