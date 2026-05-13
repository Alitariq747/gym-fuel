//
//  StatsViewModel.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2026.
//

import Foundation

@MainActor
final class StatsViewModel: ObservableObject {
    @Published private(set) var selectedWeekStart: Date
    @Published private(set) var snapshot: StatsSnapshot = .empty
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let logEntryService: LogEntryService
    private let statsCalculator: StatsCalculator

    init(
        logEntryService: LogEntryService = FirebaseLogEntryService(),
        statsCalculator: StatsCalculator = StatsCalculator(),
        calendar: Calendar = .current,
        now: Date = .now
    ) {
        self.logEntryService = logEntryService
        self.statsCalculator = statsCalculator
        self.selectedWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
    }

    func goToPreviousWeek(calendar: Calendar = .current) {
        guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedWeekStart) else { return }
        selectedWeekStart = previousWeek
    }

    func goToNextWeek(calendar: Calendar = .current) {
        guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedWeekStart) else { return }
        selectedWeekStart = nextWeek
    }

    func canGoToNextWeek(calendar: Calendar = .current, now: Date = .now) -> Bool {
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
        return selectedWeekStart < currentWeekStart
    }

    func loadStats(userId: String, targetMacros: Macros?, calendar: Calendar = .current) async {
        guard let rangeStart = calendar.date(byAdding: .day, value: -90, to: selectedWeekStart),
              let selectedWeekEnd = calendar.date(byAdding: .day, value: 7, to: selectedWeekStart) else {
            errorMessage = "Failed to compute stats date range."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let entries = try await logEntryService.fetchEntries(
                for: userId,
                from: rangeStart,
                to: selectedWeekEnd
            )
            snapshot = statsCalculator.calculate(
                entries: entries,
                targetMacros: targetMacros,
                selectedWeekStart: selectedWeekStart,
                calendar: calendar
            )
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't load your stats. Please try again."
            )
            snapshot = .empty
        }

        isLoading = false
    }
}
