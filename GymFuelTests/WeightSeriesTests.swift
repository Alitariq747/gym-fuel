//
//  WeightSeriesTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import Circa

@Suite("WeightSeries")
struct WeightSeriesTests {
    private let utc = TimeZone(identifier: "UTC")!

    /// `day` is a 1-based offset into September 2026, so the keys sort naturally.
    private func weighIn(day: Int, _ weightKg: Double) -> WeighIn {
        WeighIn(
            dateKey: String(format: "2026-09-%02d", day),
            weightKg: weightKg,
            loggedAt: Date(timeIntervalSince1970: 0),
            source: .manual
        )
    }

    private func series(_ weighIns: [WeighIn]) -> WeightSeries {
        WeightSeries(weighIns: weighIns, timeZone: utc)
    }

    private func midday(_ day: Int) throws -> Date {
        try #require(DateKey.date(from: String(format: "2026-09-%02d", day), timeZone: utc))
    }

    @Test("Empty input yields an empty series")
    func emptyInput() {
        #expect(series([]) == .empty)
        #expect(series([]).latest == nil)
    }

    @Test("Weights are drawn exactly as weighed, nothing smoothed")
    func keepsEveryReading() {
        let result = series([weighIn(day: 1, 80), weighIn(day: 2, 82), weighIn(day: 3, 79.6)])

        #expect(result.points.map(\.weightKg) == [80, 82, 79.6])
        #expect(result.latest?.weightKg == 79.6)
    }

    @Test("Unsorted input comes out in day order")
    func sortsInput() {
        let result = series([weighIn(day: 3, 81), weighIn(day: 1, 80), weighIn(day: 2, 82)])

        #expect(result.points.map(\.dateKey) == ["2026-09-01", "2026-09-02", "2026-09-03"])
    }

    @Test("Duplicate days collapse to one point, the last one winning")
    func duplicateDaysCollapse() {
        let result = series([weighIn(day: 1, 80), weighIn(day: 1, 83)])

        #expect(result.points.count == 1)
        #expect(result.points[0].weightKg == 83)
    }

    @Test("Each point sits at midday on its day")
    func middayDates() throws {
        let result = series([weighIn(day: 5, 80)])

        #expect(result.points[0].date == (try midday(5)))
    }

    @Test("Malformed date keys are dropped rather than crashing")
    func dropsMalformedKeys() {
        let result = series([
            weighIn(day: 1, 80),
            WeighIn(dateKey: "not-a-date", weightKg: 999, loggedAt: Date(), source: .manual),
            weighIn(day: 2, 82),
        ])

        #expect(result.points.map(\.weightKg) == [80, 82])
    }

    @Test("Only weigh-ins inside the range are in view")
    func pointsInRange() throws {
        let result = series((1...10).map { weighIn(day: $0, 80) })
        let range = try midday(3)...midday(5)

        #expect(result.points(in: range).map(\.dateKey) == ["2026-09-03", "2026-09-04", "2026-09-05"])
    }

    @Test("A tap picks the closest weigh-in on screen")
    func nearestToTap() throws {
        let result = series([weighIn(day: 1, 80), weighIn(day: 4, 81), weighIn(day: 10, 82)])
        let all = try midday(1)...midday(10)

        // Day 7 at midday is halfway between day 4 and day 10.
        #expect(result.nearest(to: try midday(7).addingTimeInterval(-6 * 3_600), in: all)?.dateKey == "2026-09-04")
        #expect(result.nearest(to: try midday(7).addingTimeInterval(6 * 3_600), in: all)?.dateKey == "2026-09-10")
        #expect(result.nearest(to: try midday(1), in: all)?.dateKey == "2026-09-01")
    }

    @Test("A tap never picks a weigh-in that is off screen")
    func nearestStaysInRange() throws {
        let result = series([weighIn(day: 1, 80), weighIn(day: 8, 81)])
        let lateOnly = try midday(5)...midday(10)

        #expect(result.nearest(to: try midday(2), in: lateOnly)?.dateKey == "2026-09-08")
        #expect(result.nearest(to: try midday(2), in: try midday(3)...midday(4)) == nil)
    }
}
