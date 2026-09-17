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


struct WeightTrendCalculator {

    static let defaultAlpha: Double = 0.25

  
    static let minimumPointsForTrend: Int = 3

    let alpha: Double

    init(alpha: Double = WeightTrendCalculator.defaultAlpha) {
        self.alpha = alpha
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

        var trend: Double?

        for weighIn in ordered {
            guard let date = DateKey.date(from: weighIn.dateKey, timeZone: timeZone) else {
                continue
            }

            // Seed on the first observation: trend[0] = weight[0]. Deterministic,
            // and it avoids making the first visible value depend on data the
            // user cannot see.
            let updated: Double
            if let previous = trend {
                updated = alpha * weighIn.weightKg + (1 - alpha) * previous
            } else {
                updated = weighIn.weightKg
            }
            trend = updated

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
