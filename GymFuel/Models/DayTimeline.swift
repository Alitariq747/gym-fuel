//
//  DayTimeline.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/04/2026.
//

import Foundation

struct DayTimeline: Identifiable, Equatable, Sendable {
    let date: Date
    var entries: [LogEntry]

    var id: Date { date }

    init(date: Date, entries: [LogEntry] = [], calendar: Calendar = .current) {
        let day = calendar.startOfDay(for: date)
        self.date = day
        self.entries = entries
            .filter { calendar.isDate($0.loggedAt, inSameDayAs: day) }
            .sorted { $0.loggedAt < $1.loggedAt }
    }
}
