//
//  TrialTimeline.swift
//  GymFuel
//

import Foundation

/// A free trial's length and billing date, always from the StoreKit intro offer —
/// never hardcoded (CLAUDE.md).
struct TrialTimeline {
    enum Unit {
        case day, week, month, year
    }

    let count: Int
    let unit: Unit

    init(periodValue: Int, unit: Unit, numberOfPeriods: Int) {
        count = periodValue * numberOfPeriods
        self.unit = unit
    }

    var lengthText: String {
        "\(count)-\(unitName)"
    }

    func billingDate(from start: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(byAdding: calendarComponent, value: count, to: start)
    }

    private var unitName: String {
        switch unit {
        case .day: "day"
        case .week: "week"
        case .month: "month"
        case .year: "year"
        }
    }

    private var calendarComponent: Calendar.Component {
        switch unit {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }
}
