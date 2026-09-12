//
//  DateKeyTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("DateKey")
struct DateKeyTests {
    private let utc = TimeZone(identifier: "UTC")!
    private let karachi = TimeZone(identifier: "Asia/Karachi")!
    private let newYork = TimeZone(identifier: "America/New_York")!

    /// Builds an exact instant, so no test depends on the machine's timezone.
    private func instant(
        _ year: Int, _ month: Int, _ day: Int,
        _ hour: Int = 0, _ minute: Int = 0,
        in timeZone: TimeZone
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar.date(
            from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        )!
    }

    @Test("Formats a known instant")
    func formatsKnownInstant() {
        let date = instant(2026, 9, 12, 8, 30, in: utc)
        #expect(DateKey.key(for: date, timeZone: utc) == "2026-09-12")
    }

    @Test("Zero-pads month and day")
    func zeroPads() {
        let date = instant(2026, 1, 5, 12, 0, in: utc)
        #expect(DateKey.key(for: date, timeZone: utc) == "2026-01-05")
    }

    /// Range queries and `sorted()` both rely on this. If it ever stops holding,
    /// the chart silently draws points out of order.
    @Test("Lexicographic order is chronological order")
    func lexicographicOrderIsChronological() {
        let dates = [
            instant(2026, 12, 31, 12, 0, in: utc),
            instant(2026, 1, 5, 12, 0, in: utc),
            instant(2026, 9, 12, 12, 0, in: utc),
            instant(2025, 11, 3, 12, 0, in: utc),
            instant(2026, 1, 15, 12, 0, in: utc),
        ]

        let keysSortedAsStrings = dates.map { DateKey.key(for: $0, timeZone: utc) }.sorted()
        let keysFromSortedDates = dates.sorted().map { DateKey.key(for: $0, timeZone: utc) }

        #expect(keysSortedAsStrings == keysFromSortedDates)
    }

    /// A device set to the Islamic or Buddhist calendar must not write keys in
    /// another era — they would sort wrong against every other user's.
    @Test("Always Gregorian, never the device calendar")
    func alwaysGregorian() {
        #expect(DateKey.calendar(timeZone: utc).identifier == .gregorian)

        let date = instant(2026, 9, 12, 12, 0, in: utc)
        #expect(DateKey.key(for: date, timeZone: utc).hasPrefix("2026"))
    }

    /// `ar_SA` and `ne_NP` render Arabic-Indic and Devanagari digits through
    /// `DateFormatter`. A regression guard for anyone who reintroduces one.
    @Test("ASCII digits only")
    func asciiDigitsOnly() {
        let key = DateKey.key(for: instant(2026, 9, 12, 12, 0, in: utc), timeZone: utc)
        let allowed = CharacterSet(charactersIn: "0123456789-")
        #expect(key.unicodeScalars.allSatisfy { allowed.contains($0) })
        #expect(DateKey.calendar(timeZone: utc).locale == Locale(identifier: "en_US_POSIX"))
    }

    /// The same instant is a different local day either side of midnight. This
    /// is why the key is local and not UTC.
    @Test("Timezone decides the day")
    func timezoneDecidesTheDay() {
        let date = instant(2026, 9, 12, 23, 30, in: utc)

        #expect(DateKey.key(for: date, timeZone: utc) == "2026-09-12")
        #expect(DateKey.key(for: date, timeZone: karachi) == "2026-09-13")
        #expect(DateKey.key(for: date, timeZone: newYork) == "2026-09-12")
    }

    @Test("Round-trips through parse")
    func roundTrips() {
        let date = instant(2026, 9, 12, 8, 30, in: karachi)
        let key = DateKey.key(for: date, timeZone: karachi)
        let parsed = DateKey.date(from: key, timeZone: karachi)

        #expect(parsed != nil)
        #expect(DateKey.calendar(timeZone: karachi).isDate(parsed!, inSameDayAs: date))
    }

    /// Midday parsing exists so DST never makes a local date unresolvable.
    @Test("Survives DST transitions")
    func survivesDST() {
        // Spring forward, 2am -> 3am.
        let springForward = DateKey.date(from: "2026-03-08", timeZone: newYork)
        #expect(springForward != nil)
        #expect(DateKey.key(for: springForward!, timeZone: newYork) == "2026-03-08")

        // São Paulo historically began DST at midnight, so 00:00 did not exist.
        let saoPaulo = TimeZone(identifier: "America/Sao_Paulo")!
        let midnightDST = DateKey.date(from: "2018-11-04", timeZone: saoPaulo)
        #expect(midnightDST != nil)
        #expect(DateKey.key(for: midnightDST!, timeZone: saoPaulo) == "2018-11-04")
    }

    @Test("Handles leap day")
    func handlesLeapDay() {
        let parsed = DateKey.date(from: "2028-02-29", timeZone: utc)
        #expect(parsed != nil)
        #expect(DateKey.key(for: parsed!, timeZone: utc) == "2028-02-29")
    }

    @Test("Rejects malformed keys", arguments: [
        "2026-9-5", "not-a-date", "", "2026-09", "2026-09-12T00:00:00Z", "2026-13-01", "2026-02-30",
    ])
    func rejectsMalformed(key: String) {
        #expect(DateKey.date(from: key, timeZone: utc) == nil)
    }
}
