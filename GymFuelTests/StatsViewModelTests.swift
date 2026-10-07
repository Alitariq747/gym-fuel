//
//  StatsViewModelTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("StatsViewModel week paging")
@MainActor
struct StatsViewModelTests {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        calendar.firstWeekday = 2
        return calendar
    }

    /// Wednesday 7 October 2026; its week starts Monday 5 October.
    private func now() throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 7)))
    }

    private func model(now: Date) -> StatsViewModel {
        StatsViewModel(
            logEntryService: NoLogEntries(),
            weighInService: NoWeighIns(),
            calendar: calendar,
            now: now
        )
    }

    @Test func opensOnTheCurrentWeek() throws {
        let model = model(now: try now())
        #expect(model.selectedWeekStart == calendar.date(from: DateComponents(year: 2026, month: 10, day: 5)))
    }

    @Test func nextWeekStopsAtTheCurrentWeek() throws {
        let now = try now()
        let model = model(now: now)
        let currentWeek = model.selectedWeekStart

        model.goToNextWeek(calendar: calendar, now: now)
        #expect(model.selectedWeekStart == currentWeek)

        model.goToPreviousWeek(calendar: calendar)
        model.goToNextWeek(calendar: calendar, now: now)
        #expect(model.selectedWeekStart == currentWeek)
    }
}

private struct NoLogEntries: LogEntryService {
    func fetchEntries(for userId: String, from startDate: Date, to endDate: Date) async throws -> [LogEntry] { [] }
    func observeEntries(
        for userId: String,
        from startDate: Date,
        to endDate: Date,
        onChange: @escaping LogEntryObservationHandler
    ) -> LogEntryObservationCancellation { {} }
    func saveEntryLocally(_ entry: LogEntry) throws {}
    func updateEntryLocally(_ entry: LogEntry) throws {}
    func replaceEntryLocally(_ entry: LogEntry) throws {}
    func saveEntry(_ entry: LogEntry) async throws {}
    func updateEntry(_ entry: LogEntry) async throws {}
    func deleteEntryLocally(userId: String, entryId: String) {}
}

private struct NoWeighIns: WeighInService {
    func fetchWeighIns(for userId: String, fromKey: String, throughKey: String) async throws -> [WeighIn] { [] }
    func fetchAllWeighIns(for userId: String) async throws -> [WeighIn] { [] }
    func fetchLatestWeighIn(for userId: String) async throws -> WeighIn? { nil }
    func fetchWeighIn(for userId: String, dateKey: String) async throws -> WeighIn? { nil }
    func saveWeighIn(_ weighIn: WeighIn, for userId: String) async throws {}
    func saveWeighInLocally(_ weighIn: WeighIn, for userId: String) throws {}
    func deleteWeighIn(dateKey: String, for userId: String) async throws {}
    func deleteWeighInLocally(dateKey: String, for userId: String) {}
}
