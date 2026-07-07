//
//  TimelineViewModel.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/04/2026.
//

import Foundation
import FirebasePerformance

@MainActor
final class TimelineViewModel: ObservableObject {
    @Published var selectedDate: Date = .now
    @Published private(set) var timeline: DayTimeline = DayTimeline(date: .now)
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var loggedDaysInVisibleMonth: Set<Date> = []
    @Published private(set) var isLoadingLoggedDays: Bool = false
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
    private let hapticFeedbackService: HapticFeedbackProviding
    private var observationCancellation: LogEntryObservationCancellation?
    private var localImagePreviewDataByEntryId: [String: Data] = [:]
    private var localPreparedImageDataByEntryId: [String: Data] = [:]
    private var revealedSuccessEntryIDs: Set<String> = []
    private var previousEntryStatusesByID: [String: LogEntryStatus] = [:]
    private var pendingSuccessRevealEntryIDs: Set<String> = []
    private var attemptedImageUploadRetryEntryIDs: Set<String> = []
    private var timelineLoadTrace: Trace?

    init(
        service: LogEntryService = FirebaseLogEntryService(),
        hapticFeedbackService: HapticFeedbackProviding = HapticFeedbackService()
    ) {
        self.service = service
        self.hapticFeedbackService = hapticFeedbackService
    }

    deinit {
        observationCancellation?()
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
        timelineLoadTrace = FirebaseTelemetryService.startPerformanceTrace("timeline_load_time")
        let cancellation = service.observeEntries(
            for: userId,
            from: startOfDay,
            to: endOfDay
        ) { [weak self] result in
            guard let self else { return }
            Task { @MainActor in
                switch result {
                case .success(let entries):
                    FirebaseTelemetryService.stopPerformanceTrace(
                        self.timelineLoadTrace,
                        attributes: [
                            "outcome": "success",
                        ]
                    )
                    self.timelineLoadTrace = nil
                    self.trackStatusTransitions(for: entries)
                    self.timeline = DayTimeline(date: startOfDay, entries: entries, calendar: calendar)
                    self.errorMessage = nil
                case .failure(let error):
                    FirebaseTelemetryService.stopPerformanceTrace(
                        self.timelineLoadTrace,
                        attributes: [
                            "outcome": "failure",
                        ]
                    )
                    self.timelineLoadTrace = nil
                    self.errorMessage = AppErrorMessage.message(
                        for: error,
                        fallback: "We couldn't load your timeline. Please try again."
                    )
                    self.timeline = DayTimeline(date: startOfDay)
                }
                self.isLoading = false
            }
        }
        replaceObservation(cancellation)
    }

    func loadLoggedDaysInVisibleMonth(
        containing date: Date,
        userId: String,
        calendar: Calendar = .current
    ) async {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return }

        isLoadingLoggedDays = true
        defer { isLoadingLoggedDays = false }

        do {
            let entries = try await service.fetchEntries(
                for: userId,
                from: monthInterval.start,
                to: monthInterval.end
            )
            loggedDaysInVisibleMonth = Set(entries.map { calendar.startOfDay(for: $0.loggedAt) })
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't load your logged days."
            )
        }
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

    func stopObservingEntries() {
        observationCancellation?()
        observationCancellation = nil
    }

    func replaceObservation(_ cancellation: @escaping LogEntryObservationCancellation) {
        stopObservingEntries()
        observationCancellation = cancellation
    }

    func setLocalImagePreviewData(_ data: Data, for entryId: String) {
        localImagePreviewDataByEntryId[entryId] = data
    }

    func localImagePreviewData(for entryId: String) -> Data? {
        localImagePreviewDataByEntryId[entryId]
    }

    func removeLocalImagePreviewData(for entryId: String) {
        localImagePreviewDataByEntryId.removeValue(forKey: entryId)
    }

    func setLocalPreparedImageData(_ data: Data, for entryId: String) {
        localPreparedImageDataByEntryId[entryId] = data
    }

    func localPreparedImageData(for entryId: String) -> Data? {
        localPreparedImageDataByEntryId[entryId]
    }

    func removeLocalPreparedImageData(for entryId: String) {
        localPreparedImageDataByEntryId.removeValue(forKey: entryId)
    }

    func hasRevealedSuccess(for entryId: String) -> Bool {
        revealedSuccessEntryIDs.contains(entryId)
    }

    func shouldAnimateSuccessReveal(for entry: LogEntry) -> Bool {
        entry.status == .succeeded &&
        pendingSuccessRevealEntryIDs.contains(entry.id) &&
        !revealedSuccessEntryIDs.contains(entry.id)
    }

    func markSuccessRevealed(for entryId: String) {
        revealedSuccessEntryIDs.insert(entryId)
        pendingSuccessRevealEntryIDs.remove(entryId)
    }

    func imageUploadRetryCandidates() -> [LogEntry] {
        let candidates = timeline.entries.filter {
            $0.source == .image &&
            $0.status == .succeeded &&
            $0.imageUploadStatus == .failed &&
            $0.image == nil &&
            !attemptedImageUploadRetryEntryIDs.contains($0.id)
        }
        attemptedImageUploadRetryEntryIDs.formUnion(candidates.map(\.id))
        return candidates
    }

    private func trackStatusTransitions(for entries: [LogEntry]) {
        for entry in entries {
            let previousStatus = previousEntryStatusesByID[entry.id]
            if previousStatus == .analyzing, entry.status == .succeeded {
                pendingSuccessRevealEntryIDs.insert(entry.id)
                hapticFeedbackService.notifySuccess()
            }
            previousEntryStatusesByID[entry.id] = entry.status
        }
    }
}
