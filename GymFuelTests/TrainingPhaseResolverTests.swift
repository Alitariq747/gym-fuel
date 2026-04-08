import Foundation
import Testing
@testable import GymFuel

struct TrainingPhaseResolverTests {
    private let resolver = TrainingPhaseResolver()

    @Test
    func resolveDayMode_returnsRest_forRestDay() {
        let context = makePhaseContext(
            isTrainingDay: false,
            now: baseNow,
            sessionStart: sessionStart,
            sessionDurationMinutes: 60
        )

        #expect(resolver.resolveDayMode(context: context) == .rest)
    }

    @Test
    func resolveTrainingPhase_returnsScheduled_beforePreWindow() {
        let now = preWorkoutStart.addingTimeInterval(-60)
        let context = makePhaseContext(now: now)

        #expect(resolver.resolveTrainingPhase(context: context) == .scheduled)
    }

    @Test
    func resolveTrainingPhase_returnsPreWorkout_atPreWindowBoundary() {
        let context = makePhaseContext(now: preWorkoutStart)

        #expect(resolver.resolveTrainingPhase(context: context) == .preWorkout)
    }

    @Test
    func resolveTrainingPhase_returnsInWorkout_atSessionStartBoundary() {
        let context = makePhaseContext(now: sessionStart)

        #expect(resolver.resolveTrainingPhase(context: context) == .inWorkout)
    }

    @Test
    func resolveTrainingPhase_returnsPostWorkout_atSessionEndBoundary() {
        let context = makePhaseContext(now: sessionEnd)

        #expect(resolver.resolveTrainingPhase(context: context) == .postWorkout)
    }

    @Test
    func resolveTrainingPhase_returnsSupport_atSupportStartBoundary() {
        let context = makePhaseContext(now: supportStart)

        #expect(resolver.resolveTrainingPhase(context: context) == .support)
    }

    @Test
    func resolveTrainingPhase_defaultsToScheduled_whenSessionMissing() {
        let context = makePhaseContext(now: baseNow, sessionStart: nil, sessionDurationMinutes: nil)

        #expect(resolver.resolveTrainingPhase(context: context) == .scheduled)
    }
}

private let baseNow = Date(timeIntervalSince1970: 1_735_776_000)
private let sessionStart = baseNow.addingTimeInterval(2 * 60 * 60)
private let sessionEnd = sessionStart.addingTimeInterval(60 * 60)
private let preWorkoutStart = sessionStart.addingTimeInterval(-90 * 60)
private let supportStart = sessionEnd.addingTimeInterval(180 * 60)

private func makePhaseContext(
    isTrainingDay: Bool = true,
    now: Date,
    sessionStart: Date? = sessionStart,
    sessionDurationMinutes: Int? = 60
) -> SessionStateContext {
    let dayLog = DayLog(
        id: "phase-day",
        userId: "phase-user",
        date: now,
        isTrainingDay: isTrainingDay,
        sessionStart: sessionStart,
        sessionDurationMinutes: sessionDurationMinutes,
        trainingIntensity: .normal,
        sessionType: .fullBody,
        macroTargets: Macros(calories: 2200, protein: 150, carbs: 220, fat: 70),
        consumedMacros: .zero
    )

    return SessionStateContext(
        dayLog: dayLog,
        now: now,
        consumedMacros: .zero,
        preWorkoutLeadMinutes: 90,
        supportLagMinutes: 180
    )
}
