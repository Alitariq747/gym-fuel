//
//  DateKey.swift
//  GymFuel
//

import Foundation


enum DateKey {
  
    static func calendar(timeZone: TimeZone = .current) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    /// The `"yyyy-MM-dd"` key for the local day containing `date`.
    static func key(for date: Date, timeZone: TimeZone = .current) -> String {
        let components = calendar(timeZone: timeZone)
            .dateComponents([.year, .month, .day], from: date)

        guard let year = components.year,
              let month = components.month,
              let day = components.day
        else { return "" }

        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// Midday on the local day named by `key`, or `nil` if the key is malformed.
    ///
    /// Midday rather than midnight — see rule 4 in the type documentation.
    static func date(from key: String, timeZone: TimeZone = .current) -> Date? {
        let parts = key.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else { return nil }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12

        let calendar = calendar(timeZone: timeZone)
        guard let date = calendar.date(from: components) else { return nil }

        // `Calendar.date(from:)` rolls invalid components forward — "2026-02-30"
        // would silently become 2 March. Round-trip to reject that.
        let roundTrip = calendar.dateComponents([.year, .month, .day], from: date)
        guard roundTrip.year == year, roundTrip.month == month, roundTrip.day == day else {
            return nil
        }

        return date
    }
}
