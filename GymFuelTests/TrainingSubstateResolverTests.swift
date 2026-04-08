import Foundation
import Testing
@testable import GymFuel

struct TrainingSubstateResolverTests {
    private let resolver = TrainingSubstateResolver()

    @Test
    func scheduled_overFueled_whenCaloriesHigh() {
        let context = makeContext(
            now: referenceNow,
            consumed: Macros(calories: 2400, protein: 120, carbs: 170, fat: 55)
        )

        #expect(resolver.resolveScheduledSubstate(context: context) == .overFueled)
    }

    @Test
    func scheduled_underFueled_whenCaloriesAndCarbsLow() {
        let context = makeContext(
            now: referenceNow,
            consumed: Macros(calories: 200, protein: 50, carbs: 18, fat: 12)
        )

        #expect(resolver.resolveScheduledSubstate(context: context) == .underFueled)
    }

    @Test
    func scheduled_onTarget_whenMidRange() {
        let context = makeContext(
            now: referenceNow,
            consumed: Macros(calories: 1300, protein: 90, carbs: 130, fat: 35)
        )

        #expect(resolver.resolveScheduledSubstate(context: context) == .onTarget)
    }

    @Test
    func preWorkout_needPreMeal_whenCloseAndLowCalories() {
        let now = sessionStart.addingTimeInterval(-45 * 60)
        let context = makeContext(
            now: now,
            consumed: Macros(calories: 700, protein: 60, carbs: 60, fat: 20),
            preWorkout: Macros(calories: 80, protein: 8, carbs: 10, fat: 3)
        )

        #expect(resolver.resolvePreWorkoutSubstate(context: context) == .needPreMeal)
    }

    @Test
    func preWorkout_heavy_whenFatOvershoots() {
        let now = sessionStart.addingTimeInterval(-70 * 60)
        let context = makeContext(
            now: now,
            consumed: Macros(calories: 1000, protein: 70, carbs: 80, fat: 25),
            preWorkout: Macros(calories: 320, protein: 18, carbs: 35, fat: 20)
        )

        #expect(resolver.resolvePreWorkoutSubstate(context: context) == .heavy)
    }

    @Test
    func preWorkout_heavy_whenCaloriesAtBoundary() {
        let now = sessionStart.addingTimeInterval(-70 * 60)
        let context = makeContext(
            now: now,
            consumed: Macros(calories: 1200, protein: 80, carbs: 120, fat: 30),
            preWorkout: Macros(calories: 450, protein: 25, carbs: 60, fat: 12)
        )

        #expect(resolver.resolvePreWorkoutSubstate(context: context) == .heavy)
    }

    @Test
    func preWorkout_onTarget_whenJustBelowHeavyBoundaries() {
        let now = sessionStart.addingTimeInterval(-70 * 60)
        let context = makeContext(
            now: now,
            consumed: Macros(calories: 1150, protein: 78, carbs: 115, fat: 26),
            preWorkout: Macros(calories: 449, protein: 24, carbs: 50, fat: 17)
        )

        #expect(resolver.resolvePreWorkoutSubstate(context: context) == .onTarget)
    }

    @Test
    func preWorkout_onTarget_whenBalancedAndNotHeavy() {
        let now = sessionStart.addingTimeInterval(-75 * 60)
        let context = makeContext(
            now: now,
            consumed: Macros(calories: 1100, protein: 75, carbs: 110, fat: 24),
            preWorkout: Macros(calories: 330, protein: 24, carbs: 50, fat: 10)
        )

        #expect(resolver.resolvePreWorkoutSubstate(context: context) == .onTarget)
    }

    @Test
    func inWorkout_alwaysHydratedAndFueled() {
        let now = sessionStart.addingTimeInterval(20 * 60)
        let context = makeContext(
            now: now,
            consumed: Macros(calories: 100, protein: 5, carbs: 8, fat: 2),
            preWorkout: .zero
        )

        #expect(resolver.resolveInWorkoutSubstate(context: context) == .hydratedAndFueled)
    }

    @Test
    func postWorkout_needRecoveryMeal_whenEarlyAndLowCalories() {
        let now = sessionEnd.addingTimeInterval(20 * 60)
        let context = makeContext(
            now: now,
            consumed: Macros(calories: 1300, protein: 90, carbs: 110, fat: 35),
            postWorkout: Macros(calories: 90, protein: 8, carbs: 10, fat: 3)
        )

        #expect(resolver.resolvePostWorkoutSubstate(context: context) == .needRecoveryMeal)
    }

    @Test
    func postWorkout_lowProtein_whenCaloriesOkayButProteinLow() {
        let now = sessionEnd.addingTimeInterval(120 * 60)
        let context = makeContext(
            now: now,
            consumed: Macros(calories: 1500, protein: 90, carbs: 130, fat: 40),
            postWorkout: Macros(calories: 280, protein: 15, carbs: 45, fat: 8)
        )

        #expect(resolver.resolvePostWorkoutSubstate(context: context) == .lowProteinRecovery)
    }

    @Test
    func postWorkout_recoveryOnTrack_whenProteinAndCarbsAdequate() {
        let now = sessionEnd.addingTimeInterval(120 * 60)
        let context = makeContext(
            now: now,
            consumed: Macros(calories: 1800, protein: 120, carbs: 180, fat: 48),
            postWorkout: Macros(calories: 380, protein: 30, carbs: 60, fat: 10)
        )

        #expect(resolver.resolvePostWorkoutSubstate(context: context) == .recoveryOnTrack)
    }

    @Test
    func support_underFueled_whenCaloriesAndCarbsLow() {
        let now = sessionEnd.addingTimeInterval(4 * 60 * 60)
        let context = makeContext(
            now: now,
            consumed: Macros(calories: 1400, protein: 120, carbs: 120, fat: 40)
        )

        #expect(resolver.resolveSupportSubstate(context: context) == .underFueled)
    }

    @Test
    func support_overFueled_whenCaloriesAndFatHigh() {
        let now = sessionEnd.addingTimeInterval(4 * 60 * 60)
        let context = makeContext(
            now: now,
            consumed: Macros(calories: 2600, protein: 140, carbs: 220, fat: 95)
        )

        #expect(resolver.resolveSupportSubstate(context: context) == .overFueled)
    }

    @Test
    func support_overFueled_whenFatLedAtMaintenanceCalories() {
        let now = sessionEnd.addingTimeInterval(4 * 60 * 60)
        let context = makeContext(
            now: now,
            consumed: Macros(calories: 2200, protein: 140, carbs: 205, fat: 83)
        )

        #expect(resolver.resolveSupportSubstate(context: context) == .overFueled)
    }

    @Test
    func support_onTarget_whenBalanced() {
        let now = sessionEnd.addingTimeInterval(4 * 60 * 60)
        let context = makeContext(
            now: now,
            consumed: Macros(calories: 2100, protein: 135, carbs: 205, fat: 60)
        )

        #expect(resolver.resolveSupportSubstate(context: context) == .onTarget)
    }
}

private let calendar = Calendar(identifier: .gregorian)
private let referenceNow = Date(timeIntervalSince1970: 1_735_776_000) // 2025-01-01 12:00:00 UTC
private let sessionStart = referenceNow.addingTimeInterval(2 * 60 * 60)
private let sessionEnd = sessionStart.addingTimeInterval(75 * 60)

private func makeContext(
    now: Date,
    consumed: Macros,
    preWorkout: Macros = .zero,
    postWorkout: Macros = .zero,
    support: Macros = .zero
) -> SessionStateContext {
    let dayLog = DayLog(
        id: "test-day",
        userId: "test-user",
        date: calendar.startOfDay(for: now),
        isTrainingDay: true,
        sessionStart: sessionStart,
        sessionDurationMinutes: 75,
        trainingIntensity: .normal,
        sessionType: .fullBody,
        macroTargets: Macros(calories: 2200, protein: 150, carbs: 220, fat: 70),
        consumedMacros: consumed
    )

    return SessionStateContext(
        dayLog: dayLog,
        now: now,
        consumedMacros: consumed,
        preWorkoutConsumedMacros: preWorkout,
        postWorkoutConsumedMacros: postWorkout,
        supportConsumedMacros: support,
        preWorkoutLeadMinutes: 90,
        supportLagMinutes: 180
    )
}
