//
//  TimelineViewModel.swift
//  GymFuel
//
//  Created by Codex on 15/04/2026.
//

import Foundation

@MainActor
final class TimelineViewModel: ObservableObject {
    @Published var selectedDate: Date = .now
    @Published private(set) var timeline: DayTimeline = DayTimeline(date: .now)
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    var consumedMacros: Macros {
        timeline.entries.reduce(.zero) { partial, entry in
            guard let macros = entry.feedback?.macros else { return partial }
            return Macros(
                calories: partial.calories + macros.calories,
                protein: partial.protein + macros.protein,
                carbs: partial.carbs + macros.carbs,
                fat: partial.fat + macros.fat
            )
        }
    }
    var burnedCalories: Double {
        timeline.entries.reduce(0) { partial, entry in
            partial + (entry.feedback?.estimatedCalories ?? 0)
        }
    }

    private let service: LogEntryService

    init(service: LogEntryService = FirebaseLogEntryService()) {
        self.service = service
    }

    func loadTimeline(for date: Date, userId: String, calendar: Calendar = .current) async {
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            errorMessage = "Failed to compute date range."
            return
        }

        selectedDate = startOfDay
        isLoading = true
        errorMessage = nil

        do {
            let entries = try await service.fetchEntries(
                for: userId,
                from: startOfDay,
                to: endOfDay
            )
            timeline = DayTimeline(date: startOfDay, entries: entries, calendar: calendar)
        } catch {
            errorMessage = error.localizedDescription
            timeline = DayTimeline(date: startOfDay)
        }

        isLoading = false
    }

    func goToPreviousDay(userId: String, calendar: Calendar = .current) async {
        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) else { return }
        await loadTimeline(for: previousDay, userId: userId, calendar: calendar)
    }

    func goToNextDay(userId: String, calendar: Calendar = .current) async {
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) else { return }
        await loadTimeline(for: nextDay, userId: userId, calendar: calendar)
    }

    func setSelectedDate(_ date: Date, userId: String, calendar: Calendar = .current) async {
        await loadTimeline(for: date, userId: userId, calendar: calendar)
    }
}
