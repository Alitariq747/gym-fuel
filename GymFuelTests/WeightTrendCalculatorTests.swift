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

    private func series(
        _ weighIns: [WeighIn],
        halfLifeDays: Double = WeightTrendCalculator.defaultHalfLifeDays
    ) -> WeightTrendSeries {
        WeightTrendCalculator(halfLifeDays: halfLifeDays).series(from: weighIns, timeZone: utc)
    }

    /// How much of the previous trend survives a one-day gap at the default
    /// half-life. Derived, not typed: a test that hard-codes 0.9057 fails for a
    /// rounding change rather than for a behaviour change.
    private var dailyDecay: Double {
        pow(0.5, 1.0 / WeightTrendCalculator.defaultHalfLifeDays)
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

    /// The two tests that pin the half-life *exactly*.
    ///
    /// At a gap of one half-life the decay is 0.5 and at two half-lives 0.25, so
    /// the expected trend is a clean midpoint with no floating-point residue.
    /// These assert the definition of the constant rather than restating the
    /// implementation, which is why they are worth more than the smoothed cases
    /// below.
    @Test("A gap of one half-life splits the difference exactly")
    func oneHalfLifeIsAMidpoint() {
        // Day 1 → day 8 is seven days: decay 0.5, so 0.5 × 82 + 0.5 × 80.
        let result = series([weighIn(day: 1, 80), weighIn(day: 8, 82)])

        #expect(result.points[1].trendKg == 81.0)
    }

    @Test("A gap of two half-lives leaves a quarter of the old trend")
    func twoHalfLivesQuarterWeight() {
        // Day 1 → day 15 is fourteen days: decay 0.25, so 0.75 × 82 + 0.25 × 80.
        let result = series([weighIn(day: 1, 80), weighIn(day: 15, 82)])

        #expect(result.points[1].trendKg == 81.5)
    }

    @Test("A one-day gap moves the trend by one day's decay")
    func appliesDailyDecay() {
        let result = series([weighIn(day: 1, 80), weighIn(day: 2, 82)])
        let expected = (1 - dailyDecay) * 82 + dailyDecay * 80

        #expect(abs(result.points[1].trendKg - expected) < 1e-9)
        // ~9% of the way from 80 to 82 — well under a fifth of the gap.
        #expect(result.points[1].trendKg < 80.4)
    }

    @Test("Three daily observations compound the decay")
    func threeObservations() {
        let result = series([weighIn(day: 1, 80), weighIn(day: 2, 82), weighIn(day: 3, 81)])

        let second = (1 - dailyDecay) * 82 + dailyDecay * 80
        let third = (1 - dailyDecay) * 81 + dailyDecay * second
        let expected = [80.0, second, third]

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

        // From the step onward, with a one-day gap each time:
        // trend_n = 90 - 10 * dailyDecay^n
        for (offset, point) in result.points.dropFirst(3).enumerated() {
            let expected = 90 - 10 * pow(dailyDecay, Double(offset + 1))
            #expect(abs(point.trendKg - expected) < 1e-9)
            #expect(point.trendKg < 90)
        }
    }

    /// **Replaces 4a's `gapsAreNotInterpolated`, deliberately.** That test
    /// asserted a sparse gap and an adjacent day produced the *same* trend value,
    /// which was the time-blindness bug 4b1 exists to fix. What it was really
    /// protecting — that gaps are never carried forward or interpolated into
    /// invented data points — still holds and is asserted below: two weigh-ins
    /// still produce exactly two points, however far apart they are.
    ///
    /// A 30-day-old trend should barely survive: it is four half-lives back, so
    /// the new reading takes ~95%.
    @Test("A long gap weighs more than an adjacent day, and invents no points")
    func aLongGapWeighsMore() {
        let sparse = series([weighIn(day: 1, 80), weighIn(day: 30, 82)])
        let adjacent = series([weighIn(day: 1, 80), weighIn(day: 2, 82)])

        // Nothing interpolated: still one point per observation.
        #expect(sparse.points.count == 2)
        #expect(adjacent.points.count == 2)

        #expect(sparse.points[1].trendKg > adjacent.points[1].trendKg)
        #expect(sparse.points[1].trendKg > 81.8)
        #expect(adjacent.points[1].trendKg < 80.4)
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

    /// If `halfLifeDays` were ignored, every other assertion here would still pass
    /// at the default value. Both ends of the range, because a stuck constant
    /// would satisfy only one of them.
    @Test("The half-life parameter is actually used")
    func halfLifeIsUsed() {
        let weighIns = [weighIn(day: 1, 80), weighIn(day: 2, 82), weighIn(day: 3, 79)]

        // A vanishing half-life means no memory: the trend is the measurement.
        let jumpy = series(weighIns, halfLifeDays: 0.001)
        #expect(jumpy.points.allSatisfy { abs($0.trendKg - $0.weightKg) < 1e-9 })

        // A very long one means the trend barely leaves where it was seeded.
        let sluggish = series(weighIns, halfLifeDays: 10_000)
        #expect(sluggish.points.allSatisfy { abs($0.trendKg - 80) < 0.01 })
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
