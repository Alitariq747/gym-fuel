//
//  LogComposerViewModel.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 18/04/2026.
//

import Foundation

@MainActor
final class LogComposerViewModel: ObservableObject {
    @Published var draft = LogComposerDraft()
    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String?
    private let interpretationService: LogInterpretationService
    private let logEntryService: LogEntryService
    private let mealImageUploadService: MealImageUploadService

    init(
        interpretationService: LogInterpretationService = BackendLogInterpretationService(),
        logEntryService: LogEntryService = FirebaseLogEntryService(),
        mealImageUploadService: MealImageUploadService = FirebaseMealImageUploadService()
    ) {
        self.interpretationService = interpretationService
        self.logEntryService = logEntryService
        self.mealImageUploadService = mealImageUploadService
    }

    func clearError() {
        errorMessage = nil
    }

    private func userFacingMessage(for error: Error, fallback: String? = nil) -> String {
        AppErrorMessage.message(
            for: error,
            fallback: fallback ?? "We couldn't log that entry. Please try again."
        )
    }

    private func failureFeedback(message: String) -> LogEntryFeedback {
        LogEntryFeedback(
            explanation: message,
            shortExplanation: nil,
            assumptions: [],
            confidence: nil,
            estimatedCalories: nil,
            macros: nil,
            goalFitScore: nil,
            rebalanceHint: nil
        )
    }

    func submitText(userId: String, goal: GoalType, loggedAt: Date = .now) async -> Bool {
        let text = draft.trimmedText
        guard !text.isEmpty else {
            errorMessage = "Enter something to log."
            return false
        }

        let pendingEntry = makePendingTextEntry(text: text, userId: userId, loggedAt: loggedAt)
        isSubmitting = true
        errorMessage = nil
        var didSavePendingEntry = false

        do {
            try await logEntryService.saveEntry(pendingEntry)
            didSavePendingEntry = true
            draft = LogComposerDraft()
            let interpretedEntry = try await interpretationService.interpretText(
                text,
                userId: userId,
                goal: goal,
                loggedAt: loggedAt
            )
            let resolvedEntry = LogEntry(
                id: pendingEntry.id,
                userId: pendingEntry.userId,
                status: .succeeded,
                loggedAt: pendingEntry.loggedAt,
                type: interpretedEntry.type,
                title: interpretedEntry.title,
                rawInput: interpretedEntry.rawInput,
                detail: interpretedEntry.detail,
                feedback: interpretedEntry.feedback,
                image: interpretedEntry.image
            )
            try await logEntryService.updateEntry(resolvedEntry)
            isSubmitting = false
            return true
        } catch {
            let message = userFacingMessage(for: error)
            if didSavePendingEntry {
                var failedEntry = pendingEntry
                failedEntry.status = .failed
                failedEntry.feedback = failureFeedback(message: message)
                try? await logEntryService.updateEntry(failedEntry)
            } else {
                errorMessage = message
            }
            isSubmitting = false
            return false
        }
    }

    private func makePendingTextEntry(text: String, userId: String, loggedAt: Date) -> LogEntry {
        LogEntry(userId: userId, source: .text, status: .analyzing, loggedAt: loggedAt, type: .food, title: "Analyzing entry", rawInput: text)
    }

    func retryTextEntry(_ entry: LogEntry, goal: GoalType) async -> Bool {
        isSubmitting = true
        errorMessage = nil

        do {
            var retryingEntry = entry
            retryingEntry.status = .analyzing
            retryingEntry.feedback = nil
            try await logEntryService.updateEntry(retryingEntry)

            let interpretedEntry = try await interpretationService.interpretText(
                entry.rawInput,
                userId: entry.userId,
                goal: goal,
                loggedAt: entry.loggedAt
            )
            let resolvedEntry = LogEntry(
                id: entry.id,
                userId: entry.userId,
                status: .succeeded,
                loggedAt: entry.loggedAt,
                type: interpretedEntry.type,
                title: interpretedEntry.title,
                rawInput: interpretedEntry.rawInput,
                detail: interpretedEntry.detail,
                feedback: interpretedEntry.feedback,
                image: interpretedEntry.image
            )
            try await logEntryService.updateEntry(resolvedEntry)
            isSubmitting = false
            return true
        } catch {
            let message = userFacingMessage(for: error)
            var failedEntry = entry
            failedEntry.status = .failed
            failedEntry.feedback = failureFeedback(message: message)
            try? await logEntryService.updateEntry(failedEntry)
            isSubmitting = false
            return false
        }
    }

    func retryMealImageEntry(_ entry: LogEntry, imageData: Data, goal: GoalType) async -> LogEntry? {
        isSubmitting = true
        errorMessage = nil

        do {
            var retryingEntry = entry
            retryingEntry.status = .analyzing
            retryingEntry.feedback = nil
            try await logEntryService.updateEntry(retryingEntry)

            let interpretedEntry = try await interpretationService.interpretMealImage(
                imageData,
                userId: entry.userId,
                goal: goal,
                loggedAt: entry.loggedAt
            )
            let resolvedEntry = LogEntry(
                id: entry.id,
                userId: entry.userId,
                status: .succeeded,
                loggedAt: entry.loggedAt,
                type: interpretedEntry.type,
                title: interpretedEntry.title,
                rawInput: interpretedEntry.rawInput,
                detail: interpretedEntry.detail,
                feedback: interpretedEntry.feedback,
                image: interpretedEntry.image
            )
            try await logEntryService.updateEntry(resolvedEntry)
            startBackgroundMealImageUpload(for: resolvedEntry, imageData: imageData)
            isSubmitting = false
            return resolvedEntry
        } catch {
            let message = userFacingMessage(for: error)
            var failedEntry = entry
            failedEntry.status = .failed
            failedEntry.feedback = failureFeedback(message: message)
            try? await logEntryService.updateEntry(failedEntry)
            isSubmitting = false
            return nil
        }
    }

    func submitMealImage(
        _ imageData: Data,
        userId: String,
        goal: GoalType,
        loggedAt: Date = .now,
        entryId: String = UUID().uuidString
    ) async -> LogEntry? {
        let pendingEntry = LogEntry(
            id: entryId,
            userId: userId,
            source: .image,
            status: .analyzing,
            loggedAt: loggedAt,
            type: .food,
            title: "Analyzing meal image",
            rawInput: "Meal image"
        )
        isSubmitting = true
        errorMessage = nil
        var didSavePendingEntry = false

        do {
            try await logEntryService.saveEntry(pendingEntry)
            didSavePendingEntry = true
            draft = LogComposerDraft()
            let interpretedEntry = try await interpretationService.interpretMealImage(
                imageData,
                userId: userId,
                goal: goal,
                loggedAt: loggedAt
            )
            let resolvedEntry = LogEntry(
                id: pendingEntry.id,
                userId: pendingEntry.userId,
                status: .succeeded,
                loggedAt: pendingEntry.loggedAt,
                type: interpretedEntry.type,
                title: interpretedEntry.title,
                rawInput: interpretedEntry.rawInput,
                detail: interpretedEntry.detail,
                feedback: interpretedEntry.feedback,
                image: interpretedEntry.image
            )
            try await logEntryService.updateEntry(resolvedEntry)
            startBackgroundMealImageUpload(for: resolvedEntry, imageData: imageData)
            isSubmitting = false
            return resolvedEntry
        } catch {
            let message = userFacingMessage(for: error)
            if didSavePendingEntry {
                var failedEntry = pendingEntry
                failedEntry.status = .failed
                failedEntry.feedback = failureFeedback(message: message)
                try? await logEntryService.updateEntry(failedEntry)
            } else {
                errorMessage = message
            }
            isSubmitting = false
            return nil
        }
    }

    func logSavedMeal(_ meal: SavedMeal, userId: String, loggedAt: Date = .now) async -> Bool {
        isSubmitting = true
        errorMessage = nil

        let entry = LogEntry(
            userId: userId,
            source: .savedMeal,
            loggedAt: loggedAt,
            type: .food,
            title: meal.name,
            rawInput: meal.description ?? meal.name,
            detail: meal.description,
            feedback: LogEntryFeedback(
                explanation: "Saved meal logged directly.",
                shortExplanation: nil,
                assumptions: [],
                confidence: nil,
                estimatedCalories: nil,
                macros: meal.macros,
                goalFitScore: nil,
                rebalanceHint: nil
            )
        )

        do {
            try await logEntryService.saveEntry(entry)
            draft = LogComposerDraft()
            isSubmitting = false
            return true
        } catch {
            errorMessage = userFacingMessage(
                for: error,
                fallback: "We couldn't log that saved meal. Please try again."
            )
            isSubmitting = false
            return false
        }
    }

    private func startBackgroundMealImageUpload(for entry: LogEntry, imageData: Data) {
        let mealImageUploadService = mealImageUploadService
        let logEntryService = logEntryService

        Task.detached(priority: .utility) {
            do {
                let storagePath = try await mealImageUploadService.uploadMealImage(
                    imageData,
                    userId: entry.userId,
                    entryId: entry.id
                )

                var updatedEntry = entry
                updatedEntry.image = LogEntryImage(storagePath: storagePath)
                try await logEntryService.updateEntry(updatedEntry)
            } catch {
                // Background upload is secondary to the meal log itself.
            }
        }
    }
}
