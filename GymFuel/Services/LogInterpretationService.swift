import Foundation

enum MealImageInterpretationError: LocalizedError {
    case unsupported

    var errorDescription: String? {
        switch self {
        case .unsupported:
            return "Image-based meal analysis is not available yet."
        }
    }
}

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

extension LogInterpretationService {
    func interpretMealImage(
        _ imageData: Data,
        userId: String,
        goal: GoalType,
        loggedAt: Date
    ) async throws -> LogEntry {
        throw MealImageInterpretationError.unsupported
    }
}
