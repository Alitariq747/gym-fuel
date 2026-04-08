import Foundation
import Testing
@testable import GymFuel

struct SessionToneResolverTests {
    private let resolver = SessionToneResolver()

    @Test
    func restDay_returnsCalm() {
        let context = makeToneContext(isTrainingDay: false, intensity: nil, sessionType: nil)
        #expect(resolver.resolveTone(context: context) == .calm)
    }

    @Test
    func recoveryIntensity_returnsRecovery() {
        let context = makeToneContext(isTrainingDay: true, intensity: .recovery, sessionType: .fullBody)
        #expect(resolver.resolveTone(context: context) == .recovery)
    }

    @Test
    func hardIntensityWithCardio_softensToFocused() {
        let context = makeToneContext(isTrainingDay: true, intensity: .hard, sessionType: .cardio)
        #expect(resolver.resolveTone(context: context) == .focused)
    }

    @Test
    func mobility_forcesRecovery() {
        let context = makeToneContext(isTrainingDay: true, intensity: .allOut, sessionType: .mobility)
        #expect(resolver.resolveTone(context: context) == .recovery)
    }
}

private func makeToneContext(
    isTrainingDay: Bool,
    intensity: TrainingIntensity?,
    sessionType: SessionType?
) -> SessionStateContext {
    let now = Date(timeIntervalSince1970: 1_735_776_000)
    let dayLog = DayLog(
        id: "tone-day",
        userId: "tone-user",
        date: now,
        isTrainingDay: isTrainingDay,
        sessionStart: now.addingTimeInterval(60 * 60),
        sessionDurationMinutes: 60,
        trainingIntensity: intensity,
        sessionType: sessionType,
        macroTargets: Macros(calories: 2200, protein: 150, carbs: 220, fat: 70),
        consumedMacros: .zero
    )

    return SessionStateContext(
        dayLog: dayLog,
        now: now,
        consumedMacros: .zero
    )
}
