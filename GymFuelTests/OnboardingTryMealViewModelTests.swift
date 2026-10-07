import Foundation
import Testing

@testable import LiftEats

private let words = "rice with chicken stew"

private func meal(_ breakdown: MealBreakdown? = MealFixtures.sampleBreakdown) -> TriedMeal {
    TriedMeal(
        words: words,
        title: "Rice with chicken stew",
        feedback: LogEntryFeedback(explanation: "A plate of rice with chicken stew.", breakdown: breakdown)
    )
}

private actor SentWords {
    private(set) var all: [String] = []
    func record(_ words: String) { all.append(words) }
}

@Suite("Onboarding try-meal")
@MainActor
struct OnboardingTryMealViewModelTests {
    private func model(
        restoring restored: TriedMeal? = nil,
        timeout: Duration = .seconds(5),
        sent: SentWords = SentWords(),
        answer: @escaping @Sendable () async throws -> TriedMeal = { meal() }
    ) -> OnboardingTryMealViewModel {
        OnboardingTryMealViewModel(restoring: restored, timeout: timeout) { words in
            await sent.record(words)
            return try await answer()
        }
    }

    @Test("A described meal shows Circa's guess, and Continue opens")
    func describedMeal() async {
        let sent = SentWords()
        let model = model(sent: sent)
        #expect(!model.canContinue)

        model.text = "  \(words)  "
        let task = model.submit()
        #expect(model.phase == .working)
        #expect(!model.canSubmit)
        #expect(!model.canContinue)
        await task?.value

        #expect(model.phase == .result(meal()))
        #expect(model.triedMeal == meal())
        #expect(model.canContinue)
        #expect(await sent.all == [words])
    }

    @Test("A failed estimate shows the example, marked as a failure")
    func failureShowsExample() async {
        let model = model(answer: { throw BackendLogInterpretationError.networkUnavailable })
        model.text = words
        await model.submit()?.value

        #expect(model.phase == .example(afterFailure: true))
        #expect(model.triedMeal == nil)
        #expect(model.canContinue)
    }

    @Test("No answer within the timeout shows the example")
    func timeoutShowsExample() async {
        let model = model(timeout: .milliseconds(50), answer: {
            try await Task.sleep(for: .seconds(30))
            return meal()
        })
        model.text = words
        await model.submit()?.value

        #expect(model.phase == .example(afterFailure: true))
    }

    @Test("Each failure is reported under one of four reasons")
    func failureReasons() {
        typealias Model = OnboardingTryMealViewModel
        #expect(Model.failure(for: BackendLogInterpretationError.requestTimedOut) == .timeout)
        #expect(Model.failure(for: BackendLogInterpretationError.networkUnavailable) == .offline)
        #expect(Model.failure(for: BackendLogInterpretationError.rateLimited("No tries left")) == .limit)
        #expect(Model.failure(for: BackendLogInterpretationError.appCheckFailed) == .server)
        #expect(Model.failure(for: BackendLogInterpretationError.serverUnavailable) == .server)
        #expect(Model.failure(for: CancellationError()) == .server)
    }

    @Test("An answer with no breakdown goes back to typing with their words kept")
    func noBreakdown() async {
        let model = model(answer: { meal(nil) })
        model.text = words
        await model.submit()?.value

        #expect(model.phase == .typing)
        #expect(model.foundNoMeal)
        #expect(model.text == words)
        #expect(!model.canContinue)

        let retry = model.submit()
        #expect(!model.foundNoMeal)
        await retry?.value
    }

    @Test("Choosing the example sends nothing")
    func chosenExample() async {
        let sent = SentWords()
        let model = model(sent: sent)
        model.showExample()

        #expect(model.phase == .example(afterFailure: false))
        #expect(model.canContinue)
        #expect(await sent.all.isEmpty)
    }

    @Test("Fewer than two characters cannot be sent")
    func tooShort() {
        let model = model()
        model.text = " a "
        #expect(!model.canSubmit)
        #expect(model.submit() == nil)
        #expect(model.phase == .typing)
    }

    @Test("Coming back to the step shows the earlier result without asking again")
    func restoresResult() async {
        let sent = SentWords()
        let model = model(restoring: meal(), sent: sent)

        #expect(model.phase == .result(meal()))
        #expect(model.text == words)
        #expect(!model.canSubmit)
        #expect(await sent.all.isEmpty)
    }

    @Test("Changing an amount moves the total and keeps the first guess beside it")
    func correctionShowsFirstGuess() {
        let model = model(restoring: meal())
        #expect(model.correction == nil)

        var breakdown = MealFixtures.sampleBreakdown
        breakdown.items[0].components[2].amount?.adjustedQuantity = 1
        model.correct(to: breakdown)

        #expect(model.correction == .init(firstGuess: 607, total: 514, changed: ["Mayonnaise"]))
        #expect(model.triedMeal?.feedback.breakdown == breakdown)
        #expect(model.triedMeal?.feedback.macros?.calories == 513.5)
    }

    @Test("Typing the original amount back clears the correction")
    func originalAmountClearsCorrection() {
        let model = model(restoring: meal())
        var breakdown = MealFixtures.sampleBreakdown
        breakdown.items[0].components[2].amount?.adjustedQuantity = 1
        model.correct(to: breakdown)

        breakdown.items[0].components[2].amount?.adjustedQuantity = nil
        model.correct(to: breakdown)

        #expect(model.correction == nil)
        #expect(model.canContinue)
    }

    @Test("Coming back to the step keeps their correction")
    func restoresCorrection() {
        var corrected = meal()
        corrected.feedback.breakdown?.items[0].components[2].amount?.adjustedQuantity = 1

        #expect(model(restoring: corrected).correction?.total == 514)
    }

    @Test("Text stops at 200 UTF-16 units without splitting a character")
    func textLimit() {
        let model = model()
        let full = String(repeating: "a", count: 200)
        model.text = full
        #expect(model.text == full)

        model.text = String(repeating: "a", count: 199) + "😀😀"
        #expect(model.text == String(repeating: "a", count: 199))
        #expect(OnboardingTryMealViewModel.clamped("a😀b") == "a😀b")
    }

    @Test("An install keeps one ID")
    func installID() throws {
        let domain = "OnboardingTryMealViewModelTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }

        let first = GuestInstallID.current(in: defaults)
        #expect(UUID(uuidString: first) != nil)
        #expect(GuestInstallID.current(in: defaults) == first)
    }
}
