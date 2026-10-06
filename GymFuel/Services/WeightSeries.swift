//
//  WeightSeries.swift
//  GymFuel
//

import Foundation

/// One weigh-in placed on the chart.
struct WeightPoint: Identifiable, Equatable, Sendable {
    let dateKey: String
    /// Local midday for `dateKey` — the chart's x coordinate. See `DateKey`.
    let date: Date
    let weightKg: Double

    var id: String { dateKey }
}

/// The weigh-ins in day order, exactly as the scale gave them. Pure: no Firebase, no UI.
struct WeightSeries: Equatable, Sendable {
    let points: [WeightPoint]

    static let empty = WeightSeries(points: [])

    var latest: WeightPoint? { points.last }

    func points(in domain: ClosedRange<Date>) -> [WeightPoint] {
        points.filter { domain.contains($0.date) }
    }

    /// The weigh-in a tap at `date` picks: the closest one on screen.
    func nearest(to date: Date, in domain: ClosedRange<Date>) -> WeightPoint? {
        points(in: domain).min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }
}

extension WeightSeries {
    /// Any order in. One point per day, the last occurrence winning; malformed keys are dropped.
    init(weighIns: [WeighIn], timeZone: TimeZone = .current) {
        var byDay: [String: WeighIn] = [:]
        for weighIn in weighIns {
            byDay[weighIn.dateKey] = weighIn
        }

        // Zero-padded "yyyy-MM-dd" keys sort chronologically.
        self.init(points: byDay.values
            .sorted { $0.dateKey < $1.dateKey }
            .compactMap { weighIn in
                DateKey.date(from: weighIn.dateKey, timeZone: timeZone)
                    .map { WeightPoint(dateKey: weighIn.dateKey, date: $0, weightKg: weighIn.weightKg) }
            })
    }
}
