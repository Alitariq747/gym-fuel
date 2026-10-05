import Foundation

protocol LogInterpretationService: Sendable {
    func interpretText(
        _ text: String,
        userId: String,
        goal: GoalType,
        loggedAt: Date
    ) async throws -> LogEntry

    func describeMealImage(_ imageData: Data) async throws -> String

    func interpretPhotoDescription(
        _ text: String,
        userId: String,
        goal: GoalType,
        loggedAt: Date
    ) async throws -> LogEntry
}
