//
//  WeightChartRange.swift
//  GymFuel
//

import Foundation

/// The Weight screen's 30d · 90d · All. Only changes how much of the line is in view.
enum WeightChartRange: CaseIterable, Hashable, Sendable {
    case thirtyDays
    case ninetyDays
    case all

    /// So one weigh-in, or a few close together, never stretch across the full width.
    static let minimumDays = 7

    var title: String {
        switch self {
        case .thirtyDays: return "30d"
        case .ninetyDays: return "90d"
        case .all: return "All"
        }
    }

    private var days: Int? {
        switch self {
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .all: return nil
        }
    }

    /// From the later of the range's first day and the first weigh-in's day, through
    /// the end of today.
    func domain(firstWeighIn: Date?, now: Date = .now, calendar: Calendar = .current) -> ClosedRange<Date> {
        let today = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? now
        let latestStart = calendar.date(byAdding: .day, value: -Self.minimumDays, to: end) ?? today

        let rangeStart = days.flatMap { calendar.date(byAdding: .day, value: 1 - $0, to: today) }
        let firstDay = firstWeighIn.map { calendar.startOfDay(for: $0) }
        let start = [rangeStart, firstDay].compactMap { $0 }.max() ?? latestStart

        return min(start, latestStart)...end
    }
}
