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

    func submitText(userId: String, goal: GoalType, loggedAt: Date = .now) async -> Bool {
        let text = draft.trimmedText
        guard !text.isEmpty else {
            errorMessage = "Enter something to log."
            return false
        }

        isSubmitting = true
        errorMessage = nil

        do {
            let entry = try await interpretationService.interpretText(
                text,
                userId: userId,
                goal: goal,
                loggedAt: loggedAt
            )
            try await logEntryService.saveEntry(entry)
            draft = LogComposerDraft()
            isSubmitting = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
            return false
        }
    }

    func submitMealImage(_ imageData: Data, userId: String, goal: GoalType, loggedAt: Date = .now) async -> LogEntry? {
        isSubmitting = true
        errorMessage = nil

        do {
            let entry = try await interpretationService.interpretMealImage(
                imageData,
                userId: userId,
                goal: goal,
                loggedAt: loggedAt
            )
            try await logEntryService.saveEntry(entry)
            startBackgroundMealImageUpload(for: entry, imageData: imageData)
            isSubmitting = false
            return entry
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
            return nil
        }
    }

    func logSavedMeal(_ meal: SavedMeal, userId: String, loggedAt: Date = .now) async -> Bool {
        isSubmitting = true
        errorMessage = nil

        let entry = LogEntry(
            userId: userId,
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
                rebalanceHint: nil
            )
        )

        do {
            try await logEntryService.saveEntry(entry)
            draft = LogComposerDraft()
            isSubmitting = false
            return true
        } catch {
            errorMessage = error.localizedDescription
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
