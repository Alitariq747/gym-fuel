//
//  LogEntryDetailViewModel.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 16/04/2026.
//

import Foundation

@MainActor
final class LogEntryDetailViewModel: ObservableObject {
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var aiErrorMessage: String?
    @Published private(set) var actionErrorMessage: String?
    @Published private(set) var shouldPresentSubscriptionPaywall = false

    private let service: LogEntryService
    private let interpretationService: LogInterpretationService
    private let mealImageUploadService: MealImageUploadService
    private let networkMonitor: NetworkMonitoring

    init(
        service: LogEntryService = FirebaseLogEntryService(),
        interpretationService: LogInterpretationService = BackendLogInterpretationService(),
        mealImageUploadService: MealImageUploadService = FirebaseMealImageUploadService(),
        networkMonitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.service = service
        self.interpretationService = interpretationService
        self.mealImageUploadService = mealImageUploadService
        self.networkMonitor = networkMonitor
    }

    func clearError() {
        errorMessage = nil
        aiErrorMessage = nil
        actionErrorMessage = nil
        shouldPresentSubscriptionPaywall = false
    }

    func clearSubscriptionPaywallRequest() {
        shouldPresentSubscriptionPaywall = false
    }

    private func isSubscriptionInactive(_ error: Error) -> Bool {
        guard let backendError = error as? BackendLogInterpretationError else {
            return false
        }

        if case .subscriptionInactive = backendError {
            return true
        }

        return false
    }

    func reinterpretEntry(
        _ entry: LogEntry,
        newRawInput: String,
        goal: GoalType
    ) async -> LogEntry? {
        isSaving = true
        clearAIError()

        do {
            let reinterpretedEntry = try await interpretationService.interpretText(
                newRawInput,
                userId: entry.userId,
                goal: goal,
                loggedAt: entry.loggedAt
            )

            let updatedEntry = LogEntry(
                id: entry.id,
                userId: entry.userId,
                source: entry.source,
                status: .succeeded,
                loggedAt: entry.loggedAt,
                title: reinterpretedEntry.title,
                rawInput: newRawInput,
                detail: reinterpretedEntry.detail,
                feedback: reinterpretedEntry.feedback,
                image: entry.image,
                imageUploadStatus: entry.imageUploadStatus,
                isRawInputReworded: true
            )

            // The detail screen shows the returned copy, not the listener, so
            // awaiting the server's confirmation would add a round trip to the wait.
            try service.replaceEntryLocally(updatedEntry)
            isSaving = false
            return updatedEntry
        } catch {
            if isSubscriptionInactive(error) {
                shouldPresentSubscriptionPaywall = true
            }
            setAIError(AppErrorMessage.message(
                for: error,
                fallback: "We couldn't reinterpret this entry. Please try again."
            ))
            isSaving = false
            return nil
        }
    }

    /// A typed total supersedes the breakdown that disagreed with it, rather than
    /// sitting on top of one that now describes a different meal.
    func updateMacros(for entry: LogEntry, to macros: Macros) async -> LogEntry? {
        await updateEntry(entry) { updated in
            updated.feedback = MealBreakdownCalculator.superseding(
                updated.feedback,
                withUserTotal: macros
            )
        }
    }

    func updateBreakdown(for entry: LogEntry, to breakdown: MealBreakdown) async -> LogEntry? {
        await updateEntry(entry) { updated in
            updated.feedback = updated.feedback.map { MealBreakdownCalculator.correcting($0, to: breakdown) }
        }
    }

    func updateLoggedAt(for entry: LogEntry, to loggedAt: Date) async -> LogEntry? {
        await updateEntry(entry) { updated in
            updated.loggedAt = loggedAt
        }
    }

    func deleteEntry(_ entry: LogEntry) async -> Bool {
        isSaving = true
        clearActionError()

        do {
            // Storage can't queue a delete offline, and the photo must go first:
            // only the document records where it is.
            if let storagePath = entry.image?.storagePath {
                guard networkMonitor.isConnected else {
                    setActionError("You're offline. Reconnect and try again.")
                    isSaving = false
                    return false
                }
                try await mealImageUploadService.deleteMealImage(at: storagePath)
            }
            service.deleteEntryLocally(userId: entry.userId, entryId: entry.id)
            await deleteCachedMealImage(entryId: entry.id)
            isSaving = false
            return true
        } catch {
            setActionError(AppErrorMessage.message(
                for: error,
                fallback: "We couldn't delete this entry. Please try again."
            ))
            isSaving = false
            return false
        }
    }

    private func deleteCachedMealImage(entryId: String) async {
        await Task.detached(priority: .utility) {
            MealImageCacheService().deleteImageData(for: entryId)
        }.value
    }

    func updateEntry(
        _ entry: LogEntry,
        apply changes: (inout LogEntry) -> Void
    ) async -> LogEntry? {
        var updatedEntry = entry
        changes(&updatedEntry)

        isSaving = true
        clearActionError()

        do {
            // Not awaited, for the reason given in `reinterpretEntry`.
            try service.replaceEntryLocally(updatedEntry)
            isSaving = false
            return updatedEntry
        } catch {
            setActionError(AppErrorMessage.message(
                for: error,
                fallback: "We couldn't save those changes. Please try again."
            ))
            isSaving = false
            return nil
        }
    }

    func clearAIError() {
        aiErrorMessage = nil
        errorMessage = actionErrorMessage
    }

    func clearActionError() {
        actionErrorMessage = nil
        errorMessage = aiErrorMessage
    }

    private func setAIError(_ message: String) {
        aiErrorMessage = message
        errorMessage = message
    }

    private func setActionError(_ message: String) {
        actionErrorMessage = message
        errorMessage = message
    }
}
