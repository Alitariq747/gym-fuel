//
//  WeightTrendCalculatorTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("WeightTrendCalculator")
struct WeightTrendCalculatorTests {
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

    private func series(_ weighIns: [WeighIn], alpha: Double = WeightTrendCalculator.defaultAlpha) -> WeightTrendSeries {
        WeightTrendCalculator(alpha: alpha).series(from: weighIns, timeZone: utc)
    }

    @Test("Empty input yields an empty series")
    func emptyInput() {
        #expect(series([]) == .empty)
    }

    /// Seeding is exact, not approximate — assert equality, not an epsilon.
    @Test("A single weigh-in seeds the trend exactly")
    func singleWeighInSeeds() {
        let result = series([weighIn(day: 1, 80)])

        #expect(result.points.count == 1)
        #expect(result.points[0].trendKg == result.points[0].weightKg)
    }

    @Test("Alpha is applied on the second observation")
    func appliesAlpha() {
        let result = series([weighIn(day: 1, 80), weighIn(day: 2, 82)])

        // 0.25 * 82 + 0.75 * 80 = 80.5
        #expect(abs(result.points[1].trendKg - 80.5) < 1e-9)
    }

    @Test("Three observations follow the hand-computed EMA")
    func threeObservations() {
        let result = series([weighIn(day: 1, 80), weighIn(day: 2, 82), weighIn(day: 3, 81)])
        let expected = [80.0, 80.5, 80.625]

        #expect(result.points.count == 3)
        for (point, want) in zip(result.points, expected) {
            #expect(abs(point.trendKg - want) < 1e-9)
        }
    }

    @Test("A constant weight never drifts")
    func constantWeightDoesNotDrift() {
        let result = series((1...5).map { weighIn(day: $0, 80) })
        #expect(result.points.allSatisfy { abs($0.trendKg - 80) < 1e-9 })
    }

    @Test("Step response converges without overshooting")
    func stepResponse() {
        let flat = (1...3).map { weighIn(day: $0, 80) }
        let step = (4...23).map { weighIn(day: $0, 90) }
        let result = series(flat + step)

        // From the step onward: trend_n = 90 - 10 * 0.75^n
        for (offset, point) in result.points.dropFirst(3).enumerated() {
            let expected = 90 - 10 * pow(0.75, Double(offset + 1))
            #expect(abs(point.trendKg - expected) < 1e-9)
            #expect(point.trendKg < 90)
        }
    }

    /// Pins the "skip gaps, never carry forward or interpolate" decision so it
    /// cannot be changed silently. Carrying forward would drive the trend onto
    /// the last measurement and read as *more* certain than the data supports.
    @Test("A long gap is one observation, not many")
    func gapsAreNotInterpolated() {
        let sparse = series([weighIn(day: 1, 80), weighIn(day: 30, 82)])
        let adjacent = series([weighIn(day: 1, 80), weighIn(day: 2, 82)])

        #expect(sparse.points.count == 2)
        #expect(abs(sparse.points[1].trendKg - adjacent.points[1].trendKg) < 1e-9)
    }

    @Test("Unsorted input is ordered before smoothing")
    func sortsInput() {
        let ordered = series([weighIn(day: 1, 80), weighIn(day: 2, 82)])
        let shuffled = series([weighIn(day: 2, 82), weighIn(day: 1, 80)])

        #expect(ordered.points.map(\.dateKey) == shuffled.points.map(\.dateKey))
        #expect(abs(ordered.points[1].trendKg - shuffled.points[1].trendKg) < 1e-9)
    }

    @Test("Duplicate days collapse to one point")
    func duplicateDaysCollapse() {
        let result = series([weighIn(day: 1, 80), weighIn(day: 1, 83)])

        #expect(result.points.count == 1)
        #expect(result.points[0].weightKg == 83)
    }

    @Test("hasTrend turns on at three points")
    func hasTrendThreshold() {
        #expect(series([]).hasTrend == false)
        #expect(series([weighIn(day: 1, 80)]).hasTrend == false)
        #expect(series([weighIn(day: 1, 80), weighIn(day: 2, 81)]).hasTrend == false)
        #expect(series((1...3).map { weighIn(day: $0, 80) }).hasTrend)
    }

    /// If alpha were ignored, every other assertion here would still pass at the
    /// default value.
    @Test("Alpha of 1 tracks the measurement exactly")
    func alphaIsUsed() {
        let result = series([weighIn(day: 1, 80), weighIn(day: 2, 82), weighIn(day: 3, 79)], alpha: 1)
        #expect(result.points.allSatisfy { $0.trendKg == $0.weightKg })
    }

    /// An EMA is a convex combination, so the trend can never leave the range of
    /// the observations seen so far. One assertion that catches a whole family of
    /// sign and ordering errors.
    @Test("Trend stays within the observed range")
    func convexity() {
        var generator = SystemRandomNumberGenerator()
        let weighIns = (1...200).map { day in
            WeighIn(
                dateKey: String(format: "2026-%02d-%02d", (day / 28) + 1, (day % 28) + 1),
                weightKg: Double.random(in: 60...120, using: &generator),
                loggedAt: Date(timeIntervalSince1970: 0),
                source: .manual
            )
        }

        let result = series(weighIns)
        var seenMin = Double.greatestFiniteMagnitude
        var seenMax = -Double.greatestFiniteMagnitude

        for point in result.points {
            seenMin = min(seenMin, point.weightKg)
            seenMax = max(seenMax, point.weightKg)

            #expect(point.trendKg.isFinite)
            #expect(point.trendKg >= seenMin - 1e-9)
            #expect(point.trendKg <= seenMax + 1e-9)
        }
    }

    @Test("Malformed date keys are dropped rather than crashing")
    func dropsMalformedKeys() {
        let result = series([
            weighIn(day: 1, 80),
            WeighIn(dateKey: "not-a-date", weightKg: 999, loggedAt: Date(), source: .manual),
            weighIn(day: 2, 82),
        ])

        #expect(result.points.count == 2)
        #expect(result.points.allSatisfy { $0.weightKg < 100 })
    }
}
