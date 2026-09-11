import Foundation

protocol LogInterpretationService: Sendable {
    func interpretText(
        _ text: String,
        userId: String,
        goal: GoalType,
        loggedAt: Date
    ) async throws -> LogEntry

    func interpretMealImage(
        _ imageData: Data,
        userId: String,
        goal: GoalType,
        loggedAt: Date
    ) async throws -> LogEntry
}
