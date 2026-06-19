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
            assumptions: [],
            confidence: nil,
            estimatedCalories: nil,
            macros: nil,
            goalFitScore: nil,
            estimatedItems: nil
        )
    }

    private func feedback(_ feedback: LogEntryFeedback?, scoredFor goal: GoalType) -> LogEntryFeedback? {
        var feedback = feedback
        feedback?.goalType = goal
        return feedback
    }

    func submitText(userId: String, goal: GoalType, loggedAt: Date = .now) async -> Bool {
        let text = draft.trimmedText
        guard !text.isEmpty else {
            errorMessage = "Enter something to log."
            return false
        }

        let pendingEntry = makePendingTextEntry(text: text, userId: userId, loggedAt: loggedAt)
        let trace = FirebaseTelemetryService.startPerformanceTrace("text_meal_log_total")
        isSubmitting = true
        errorMessage = nil
        var didSavePendingEntry = false

        do {
            FirebaseTelemetryService.logMealAIEvent("submit_started", source: "text")
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
                source: .text,
                status: .succeeded,
                loggedAt: pendingEntry.loggedAt,
                type: interpretedEntry.type,
                title: interpretedEntry.title,
                rawInput: interpretedEntry.rawInput,
                detail: interpretedEntry.detail,
                feedback: feedback(interpretedEntry.feedback, scoredFor: goal),
                image: interpretedEntry.image
            )
            try await logEntryService.updateEntry(resolvedEntry)
            FirebaseTelemetryService.logMealAIEvent("submit_succeeded", source: "text")
            FirebaseTelemetryService.stopPerformanceTrace(
                trace,
                attributes: [
                    "source": "text",
                    "outcome": "success",
                ]
            )
            isSubmitting = false
            return true
        } catch {
            FirebaseTelemetryService.logMealAIEvent("submit_failed", source: "text")
            FirebaseTelemetryService.stopPerformanceTrace(
                trace,
                attributes: [
                    "source": "text",
                    "outcome": "failure",
                ]
            )
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
            FirebaseTelemetryService.logMealAIEvent("retry_started", source: "text")
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
                source: .text,
                status: .succeeded,
                loggedAt: entry.loggedAt,
                type: interpretedEntry.type,
                title: interpretedEntry.title,
                rawInput: interpretedEntry.rawInput,
                detail: interpretedEntry.detail,
                feedback: feedback(interpretedEntry.feedback, scoredFor: goal),
                image: interpretedEntry.image
            )
            try await logEntryService.updateEntry(resolvedEntry)
            FirebaseTelemetryService.logMealAIEvent("retry_succeeded", source: "text")
            isSubmitting = false
            return true
        } catch {
            FirebaseTelemetryService.logMealAIEvent("retry_failed", source: "text")
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
            FirebaseTelemetryService.logMealAIEvent("retry_started", source: "image")
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
                source: .image,
                status: .succeeded,
                loggedAt: entry.loggedAt,
                type: interpretedEntry.type,
                title: interpretedEntry.title,
                rawInput: interpretedEntry.rawInput,
                detail: interpretedEntry.detail,
                feedback: feedback(interpretedEntry.feedback, scoredFor: goal),
                image: interpretedEntry.image,
                imageUploadStatus: .localOnly
            )
            try await logEntryService.updateEntry(resolvedEntry)
            startBackgroundMealImageUpload(for: resolvedEntry, imageData: imageData)
            FirebaseTelemetryService.logMealAIEvent("retry_succeeded", source: "image")
            isSubmitting = false
            return resolvedEntry
        } catch {
            FirebaseTelemetryService.logMealAIEvent("retry_failed", source: "image")
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
            rawInput: "Meal image",
            imageUploadStatus: .localOnly
        )
        let trace = FirebaseTelemetryService.startPerformanceTrace("image_meal_log_total")
        isSubmitting = true
        errorMessage = nil
        var didSavePendingEntry = false

        do {
            FirebaseTelemetryService.logMealAIEvent("submit_started", source: "image")
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
                source: .image,
                status: .succeeded,
                loggedAt: pendingEntry.loggedAt,
                type: interpretedEntry.type,
                title: interpretedEntry.title,
                rawInput: interpretedEntry.rawInput,
                detail: interpretedEntry.detail,
                feedback: feedback(interpretedEntry.feedback, scoredFor: goal),
                image: interpretedEntry.image,
                imageUploadStatus: .localOnly
            )
            try await logEntryService.updateEntry(resolvedEntry)
            startBackgroundMealImageUpload(for: resolvedEntry, imageData: imageData)
            FirebaseTelemetryService.logMealAIEvent("submit_succeeded", source: "image")
            FirebaseTelemetryService.stopPerformanceTrace(
                trace,
                attributes: [
                    "source": "image",
                    "outcome": "success",
                ]
            )
            isSubmitting = false
            return resolvedEntry
        } catch {
            FirebaseTelemetryService.logMealAIEvent("submit_failed", source: "image")
            FirebaseTelemetryService.stopPerformanceTrace(
                trace,
                attributes: [
                    "source": "image",
                    "outcome": "failure",
                ]
            )
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
                assumptions: [],
                confidence: nil,
                estimatedCalories: nil,
                macros: meal.macros,
                goalFitScore: nil,
                estimatedItems: nil
            )
        )

        do {
            try await logEntryService.saveEntry(entry)
            draft = LogComposerDraft()
            FirebaseTelemetryService.logSavedMealEvent("log_succeeded")
            isSubmitting = false
            return true
        } catch {
            FirebaseTelemetryService.logSavedMealEvent("log_failed")
            errorMessage = userFacingMessage(
                for: error,
                fallback: "We couldn't log that saved meal. Please try again."
            )
            isSubmitting = false
            return false
        }
    }

    private func canRetryMealImageUpload(for entry: LogEntry) -> Bool {
        entry.source == .image &&
        entry.status == .succeeded &&
        entry.imageUploadStatus == .failed &&
        entry.image == nil
    }

    func retryFailedMealImageUploadIfNeeded(for entry: LogEntry) {
        guard canRetryMealImageUpload(for: entry) else { return }
        let mealImageUploadService = mealImageUploadService
        let logEntryService = logEntryService

        Task.detached(priority: .utility) {
            guard let imageData = MealImageCacheService().imageData(for: entry.id) else { return }
            var uploadingEntry = entry
            uploadingEntry.imageUploadStatus = .uploading
            try? await logEntryService.updateEntry(uploadingEntry)
            let trace = FirebaseTelemetryService.startPerformanceTrace("image_upload_time")

            do {
                let storagePath = try await mealImageUploadService.uploadMealImage(
                    imageData,
                    userId: entry.userId,
                    entryId: entry.id
                )
                var uploadedEntry = uploadingEntry
                uploadedEntry.image = LogEntryImage(storagePath: storagePath)
                uploadedEntry.imageUploadStatus = .uploaded
                try await logEntryService.updateEntry(uploadedEntry)
                FirebaseTelemetryService.stopPerformanceTrace(
                    trace,
                    attributes: [
                        "source": "image_retry",
                        "outcome": "success",
                    ]
                )
            } catch {
                FirebaseTelemetryService.recordNonFatal(
                    error,
                    reason: "meal_image_upload_retry_failed",
                    metadata: [
                        "entry_id": entry.id,
                        "source": "image_retry",
                    ]
                )
                var failedEntry = entry
                failedEntry.imageUploadStatus = .failed
                try? await logEntryService.updateEntry(failedEntry)
                FirebaseTelemetryService.stopPerformanceTrace(
                    trace,
                    attributes: [
                        "source": "image_retry",
                        "outcome": "failure",
                    ]
                )
            }
        }
    }

    private func startBackgroundMealImageUpload(for entry: LogEntry, imageData: Data) {
        let mealImageUploadService = mealImageUploadService
        let logEntryService = logEntryService

        Task.detached(priority: .utility) {
            let trace = FirebaseTelemetryService.startPerformanceTrace("image_upload_time")
            do {
                let storagePath = try await mealImageUploadService.uploadMealImage(
                    imageData,
                    userId: entry.userId,
                    entryId: entry.id
                )

                var updatedEntry = entry
                updatedEntry.image = LogEntryImage(storagePath: storagePath)
                updatedEntry.imageUploadStatus = .uploaded
                try await logEntryService.updateEntry(updatedEntry)
                FirebaseTelemetryService.stopPerformanceTrace(
                    trace,
                    attributes: [
                        "source": "image_submit",
                        "outcome": "success",
                    ]
                )
            } catch {
                FirebaseTelemetryService.recordNonFatal(
                    error,
                    reason: "meal_image_upload_failed",
                    metadata: [
                        "entry_id": entry.id,
                        "source": "image_submit",
                    ]
                )
                var failedUploadEntry = entry
                failedUploadEntry.imageUploadStatus = .failed
                try? await logEntryService.updateEntry(failedUploadEntry)
                FirebaseTelemetryService.stopPerformanceTrace(
                    trace,
                    attributes: [
                        "source": "image_submit",
                        "outcome": "failure",
                    ]
                )
            }
        }
    }
}
