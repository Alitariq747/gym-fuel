//
//  WeightTrendCalculator.swift
//  GymFuel
//

import Foundation

/// One day on the trend chart: what the scale said, and what the smoothed line
/// says.
struct WeightTrendPoint: Identifiable, Equatable, Sendable {
    let dateKey: String
    /// Local midday for `dateKey` — the chart's x coordinate. See `DateKey`.
    let date: Date
    /// The measurement. Rendered solid: this is *known*.
    let weightKg: Double
    /// The exponential moving average. Rendered dotted: this is *estimated*.
    let trendKg: Double

    var id: String { dateKey }
}

struct WeightTrendSeries: Equatable, Sendable {
    let points: [WeightTrendPoint]

    static let empty = WeightTrendSeries(points: [])

    var latest: WeightTrendPoint? { points.last }

    /// Whether there is enough data to draw the trend line at all.
    var hasTrend: Bool { points.count >= WeightTrendCalculator.minimumPointsForTrend }
}

/// Smooths a series of weigh-ins into a trend line.
///
/// Pure arithmetic, no I/O — the same shape as `StatsCalculator`, and injected
/// into a ViewModel with a concrete default.
///
/// The trend exists because day-to-day scale weight moves with water, glycogen
/// and gut contents rather than with fat, so a single reading is not a direction.
struct WeightTrendCalculator {
    /// How long a weigh-in takes to lose half its influence on the trend.
    ///
    /// Smoothing is expressed as a half-life **in days** rather than a fixed
    /// weight per observation. 4a used a fixed `alpha = 0.25` per observation,
    /// which meant a 30-day gap and a 1-day gap did identical arithmetic —
    /// harmless while the trend was only *displayed*, wrong the moment anything
    /// reads a rate of change off it. A time-unaware average feeding a time-aware
    /// rate is exactly where a plausible-looking wrong number comes from.
    ///
    /// Seven days, not the ~3.5 that would preserve 4a's numbers for a daily
    /// weigher. The product's cadence is the weekly check-in, and at a 3.5-day
    /// half-life a weekly weigher's "trend" lands within 13% of the raw reading —
    /// smoothing in name only. At seven, a week-old reading still carries half
    /// its weight.
    static let defaultHalfLifeDays: Double = 7

    /// Below this, `hasTrend` is false and the card shows an insufficient-data
    /// state instead of a line.
    ///
    /// Three, not two. At one point the trend *is* the measurement — a tautology
    /// drawn as a line. At two it is the first measurement plus one partial step
    /// toward the second, which renders near-flat and reads as "your weight is
    /// stable" on the strength of two readings. Three is the first count at which
    /// the line has two segments and therefore expresses a direction.
    static let minimumPointsForTrend: Int = 3

    let halfLifeDays: Double

    init(halfLifeDays: Double = WeightTrendCalculator.defaultHalfLifeDays) {
        self.halfLifeDays = halfLifeDays
    }

    /// How much of the *previous* trend survives across a gap of `days`.
    ///
    /// The new reading takes `1 - decay`. At one day that is 9%, at seven days
    /// 50%, at thirty days 95% — an old trend stops pretending to know anything
    /// about today.
    func decay(overDays days: Int) -> Double {
        pow(0.5, Double(days) / halfLifeDays)
    }

    /// - Parameter weighIns: any order; duplicates by day are tolerated.
    func series(from weighIns: [WeighIn], timeZone: TimeZone = .current) -> WeightTrendSeries {
        // Firestore cannot produce duplicate keys — a day is a document ID — but
        // this is a pure function and should not depend on its caller's
        // invariants. Last occurrence wins.
        var byDay: [String: WeighIn] = [:]
        for weighIn in weighIns {
            byDay[weighIn.dateKey] = weighIn
        }

        // Lexicographic order on zero-padded "yyyy-MM-dd" **is** chronological
        // order. Do not "fix" this into a Date sort.
        let ordered = byDay.values.sorted { $0.dateKey < $1.dateKey }

        var points: [WeightTrendPoint] = []
        points.reserveCapacity(ordered.count)

        let calendar = DateKey.calendar(timeZone: timeZone)
        var previousTrend: Double?
        var previousDate: Date?

        for weighIn in ordered {
            guard let date = DateKey.date(from: weighIn.dateKey, timeZone: timeZone) else {
                continue
            }

            // Seed on the first observation: trend[0] = weight[0]. Deterministic,
            // and it avoids making the first visible value depend on data the
            // user cannot see.
            let updated: Double
            if let previous = previousTrend, let previousDate {
                // Whole days from the calendar, not `timeIntervalSince / 86400`.
                // `DateKey.date(from:)` returns midday precisely so that a DST
                // transition cannot round a day away here.
                let elapsed = calendar.dateComponents([.day], from: previousDate, to: date).day ?? 1
                // Dedup by key and the sort above already guarantee a forward
                // step, but clamping makes a zero-day decay of 1.0 — a trend
                // that can never move — unreachable rather than merely unlikely.
                let decayFactor = decay(overDays: max(1, elapsed))
                updated = (1 - decayFactor) * weighIn.weightKg + decayFactor * previous
            } else {
                updated = weighIn.weightKg
            }
            previousTrend = updated
            previousDate = date

            points.append(
                WeightTrendPoint(
                    dateKey: weighIn.dateKey,
                    date: date,
                    weightKg: weighIn.weightKg,
                    trendKg: updated
                )
            )
        }

        return WeightTrendSeries(points: points)
    }
}
