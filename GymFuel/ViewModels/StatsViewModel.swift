//
//  StatsViewModel.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2026.
//

import Foundation

@MainActor
final class StatsViewModel: ObservableObject {
    /// How far back the weight chart looks. Matches the streak window below, so
    /// there is one "recent history" figure rather than two.
    static let trendWindowDays = 90

    @Published private(set) var selectedWeekStart: Date
    @Published private(set) var snapshot: StatsSnapshot = .empty
    @Published private(set) var weightTrend: WeightTrendSeries = .empty
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let logEntryService: LogEntryService
    private let statsCalculator: StatsCalculator
    private let weighInService: WeighInService
    private let weightTrendCalculator: WeightTrendCalculator

    init(
        logEntryService: LogEntryService = FirebaseLogEntryService(),
        statsCalculator: StatsCalculator = StatsCalculator(),
        weighInService: WeighInService = FirebaseWeighInService(),
        weightTrendCalculator: WeightTrendCalculator = WeightTrendCalculator(),
        calendar: Calendar = .current,
        now: Date = .now
    ) {
        self.logEntryService = logEntryService
        self.statsCalculator = statsCalculator
        self.weighInService = weighInService
        self.weightTrendCalculator = weightTrendCalculator
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

    /// The window the weight chart covers, ending at the selected week so the
    /// week picker still means something.
    func trendWindow(calendar: Calendar = .current, timeZone: TimeZone = .current) -> (fromKey: String, throughKey: String, start: Date, end: Date)? {
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: selectedWeekStart),
              let windowStart = calendar.date(byAdding: .day, value: -Self.trendWindowDays, to: weekEnd)
        else { return nil }

        return (
            DateKey.key(for: windowStart, timeZone: timeZone),
            DateKey.key(for: weekEnd, timeZone: timeZone),
            windowStart,
            weekEnd
        )
    }

    /// Deliberately **separate** from `loadStats`, with its own error handling.
    ///
    /// `loadStats` blanks `snapshot` and sets `errorMessage` on any throw, and
    /// `StatsView` renders only the error when that is set. Folding the weigh-in
    /// read into it would mean a missing or mis-deployed rule on the new
    /// subcollection takes down the entire Week screen — calories, macros,
    /// streak and all — for every live user. Isolated, the worst case is an empty
    /// weight card.
    func loadWeightTrend(userId: String, calendar: Calendar = .current, timeZone: TimeZone = .current) async {
        guard let window = trendWindow(calendar: calendar, timeZone: timeZone) else {
            weightTrend = .empty
            return
        }

        do {
            let weighIns = try await weighInService.fetchWeighIns(
                for: userId,
                fromKey: window.fromKey,
                throughKey: window.throughKey
            )
            weightTrend = weightTrendCalculator.series(from: weighIns, timeZone: timeZone)
        } catch {
            FirebaseTelemetryService.recordNonFatal(
                error,
                reason: "weigh_in_fetch_failed",
                metadata: ["fromKey": window.fromKey, "throughKey": window.throughKey]
            )
            weightTrend = .empty
        }
    }

    func loadStats(userId: String, targetMacros: Macros?, calendar: Calendar = .current) async {
        let today = calendar.startOfDay(for: .now)
        guard let selectedWeekEnd = calendar.date(byAdding: .day, value: 7, to: selectedWeekStart),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
              let currentStreakRangeStart = calendar.date(byAdding: .day, value: -90, to: today) else {
            errorMessage = "Failed to compute stats date range."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let weeklyEntries = try await logEntryService.fetchEntries(
                for: userId,
                from: selectedWeekStart,
                to: selectedWeekEnd
            )
            let currentStreakEntries = try await logEntryService.fetchEntries(
                for: userId,
                from: currentStreakRangeStart,
                to: tomorrow
            )
            snapshot = statsCalculator.calculate(
                weeklyEntries: weeklyEntries,
                currentStreakEntries: currentStreakEntries,
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
