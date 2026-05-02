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

    private let service: LogEntryService
    private let interpretationService: LogInterpretationService
    private let mealImageUploadService: MealImageUploadService

    init(
        service: LogEntryService = FirebaseLogEntryService(),
        interpretationService: LogInterpretationService = BackendLogInterpretationService(),
        mealImageUploadService: MealImageUploadService = FirebaseMealImageUploadService()
    ) {
        self.service = service
        self.interpretationService = interpretationService
        self.mealImageUploadService = mealImageUploadService
    }

    func clearError() {
        errorMessage = nil
        aiErrorMessage = nil
        actionErrorMessage = nil
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
                loggedAt: entry.loggedAt,
                type: reinterpretedEntry.type,
                title: reinterpretedEntry.title,
                rawInput: newRawInput,
                detail: reinterpretedEntry.detail,
                feedback: reinterpretedEntry.feedback
            )

            try await service.updateEntry(updatedEntry)
            isSaving = false
            return updatedEntry
        } catch {
            setAIError(error.localizedDescription)
            isSaving = false
            return nil
        }
    }

    func updateMacros(for entry: LogEntry, to macros: Macros) async -> LogEntry? {
        await updateEntry(entry) { updated in
            if updated.feedback == nil {
                updated.feedback = LogEntryFeedback(
                    explanation: "",
                    assumptions: [],
                    confidence: nil,
                    estimatedCalories: nil,
                    macros: macros,
                    goalFitScore: nil,
                    rebalanceHint: nil
                )
            } else {
                updated.feedback?.macros = macros
            }
        }
    }

    func updateCaloriesBurned(for entry: LogEntry, to caloriesBurned: Double) async -> LogEntry? {
        await updateEntry(entry) { updated in
            if updated.feedback == nil {
                updated.feedback = LogEntryFeedback(
                    explanation: "",
                    assumptions: [],
                    confidence: nil,
                    estimatedCalories: caloriesBurned,
                    macros: nil,
                    goalFitScore: nil,
                    rebalanceHint: nil
                )
            } else {
                updated.feedback?.estimatedCalories = caloriesBurned
            }
        }
    }

    func deleteEntry(_ entry: LogEntry) async -> Bool {
        isSaving = true
        clearActionError()

        do {
            if let storagePath = entry.image?.storagePath {
                try await mealImageUploadService.deleteMealImage(at: storagePath)
            }
            try await service.deleteEntry(userId: entry.userId, entryId: entry.id)
            isSaving = false
            return true
        } catch {
            setActionError(error.localizedDescription)
            isSaving = false
            return false
        }
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
            try await service.updateEntry(updatedEntry)
            isSaving = false
            return updatedEntry
        } catch {
            setActionError(error.localizedDescription)
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
