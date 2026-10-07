import Combine
import Foundation

@MainActor
final class OnboardingTryMealViewModel: ObservableObject {
    typealias Estimator = @Sendable (String) async throws -> TriedMeal

    enum Phase: Equatable {
        case typing
        case working
        case result(TriedMeal)
        case example(afterFailure: Bool)
    }

    enum Failure: String {
        case timeout, offline, server, limit
    }

    struct Correction: Equatable {
        let firstGuess: Int
        let total: Int
        let changed: [String]
    }

    /// The backend measures JavaScript string length, which is UTF-16 (build-order 15a).
    static let maxTextLength = 200

    @Published var text = "" {
        didSet {
            guard text.utf16.count > Self.maxTextLength else { return }
            text = Self.clamped(text)
        }
    }
    @Published private(set) var phase: Phase
    /// The last answer had no breakdown to show, so they can say it another way.
    @Published private(set) var foundNoMeal = false

    private let estimate: Estimator
    private let timeout: Duration

    /// 20 s, not 15: about one Luna call in eight takes longer than 12 s.
    init(
        restoring meal: TriedMeal?,
        timeout: Duration = .seconds(20),
        estimate: @escaping Estimator = { try await BackendLogInterpretationService().tryMeal($0) }
    ) {
        self.timeout = timeout
        self.estimate = estimate
        phase = meal.map(Phase.result) ?? .typing
        text = meal?.words ?? ""
    }

    var canSubmit: Bool {
        phase == .typing && text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    var canContinue: Bool {
        switch phase {
        case .result, .example: true
        case .typing, .working: false
        }
    }

    var triedMeal: TriedMeal? {
        if case .result(let meal) = phase { meal } else { nil }
    }

    /// Nil until they change an amount, and again if they type the original back.
    var correction: Correction? {
        guard let breakdown = triedMeal?.feedback.breakdown else { return nil }
        let calculator = MealBreakdownCalculator()
        let changed = calculator.adjustedParts(of: breakdown)
        guard !changed.isEmpty else { return nil }

        return Correction(
            firstGuess: Int(calculator.total(of: calculator.firstGuess(of: breakdown)).calories.rounded()),
            total: Int(calculator.total(of: breakdown).calories.rounded()),
            changed: changed
        )
    }

    func correct(to breakdown: MealBreakdown) {
        guard case .result(var meal) = phase else { return }
        meal.feedback = MealBreakdownCalculator.correcting(meal.feedback, to: breakdown)
        phase = .result(meal)
        log("meal_try_item_edited")
    }

    @discardableResult
    func submit() -> Task<Void, Never>? {
        guard canSubmit else { return nil }
        let words = text.trimmingCharacters(in: .whitespacesAndNewlines)
        phase = .working
        foundNoMeal = false
        log("meal_try_submitted")

        return Task { [estimate, timeout] in
            do {
                let meal = try await Self.timedEstimate(words, using: estimate, within: timeout)
                guard meal.feedback.breakdown?.isSupported == true else {
                    foundNoMeal = true
                    phase = .typing
                    return
                }
                phase = .result(meal)
                log("meal_try_succeeded")
            } catch {
                log("meal_try_failed_\(Self.failure(for: error).rawValue)")
                showExample(afterFailure: true)
            }
        }
    }

    func showExample(afterFailure: Bool = false) {
        phase = .example(afterFailure: afterFailure)
        log("meal_try_example_shown")
    }

    static func failure(for error: Error) -> Failure {
        switch error as? BackendLogInterpretationError {
        case .requestTimedOut: .timeout
        case .networkUnavailable: .offline
        case .rateLimited: .limit
        default: .server
        }
    }

    static func clamped(_ text: String) -> String {
        var clamped = text
        while clamped.utf16.count > maxTextLength { clamped.removeLast() }
        return clamped
    }

    private static func timedEstimate(
        _ words: String,
        using estimate: @escaping Estimator,
        within timeout: Duration
    ) async throws -> TriedMeal {
        try await withThrowingTaskGroup(of: TriedMeal.self) { group in
            defer { group.cancelAll() }

            group.addTask { try await estimate(words) }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw BackendLogInterpretationError.requestTimedOut
            }

            guard let meal = try await group.next() else {
                throw BackendLogInterpretationError.requestTimedOut
            }
            return meal
        }
    }

    private func log(_ action: String) {
        FirebaseTelemetryService.logOnboardingEvent(action)
    }
}
