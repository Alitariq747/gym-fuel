//
//  WeighInImportPlannerTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// The rules that decide whether an Apple Health reading becomes a weigh-in.
///
/// Every one of these has a failure mode that produces plausible-looking data
/// rather than a crash, which is why they live in a pure type and are pinned
/// here rather than verified by tapping through the Health app.
@Suite("WeighInImportPlanner")
struct WeighInImportPlannerTests {
    private let utc = TimeZone(identifier: "UTC")!
    private let planner = WeighInImportPlanner()

    /// A sample at `hour:minute` UTC on 12 September 2026, unless `day` says otherwise.
    private func sample(day: Int = 12, hour: Int, minute: Int = 0, _ weightKg: Double) -> HealthKitWeightSample {
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = day
        components.hour = hour
        components.minute = minute

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc

        return HealthKitWeightSample(
            recordedAt: calendar.date(from: components)!,
            weightKg: weightKg
        )
    }

    private func existing(day: Int = 12, _ weightKg: Double, source: WeighInSource) -> WeighIn {
        WeighIn(
            dateKey: String(format: "2026-09-%02d", day),
            weightKg: weightKg,
            loggedAt: Date(timeIntervalSince1970: 0),
            source: source
        )
    }

    private func plan(_ samples: [HealthKitWeightSample], existing: [WeighIn] = []) -> [WeighIn] {
        planner.plan(samples: samples, existing: existing, timeZone: utc)
    }

    // MARK: - Which sample owns a day

    @Test("The earliest sample of the day wins")
    func earliestSampleWins() {
        let planned = plan([
            sample(hour: 21, 85.0),
            sample(hour: 7, 83.4),
            sample(hour: 13, 84.1),
        ])

        #expect(planned.count == 1)
        #expect(planned[0].weightKg == 83.4)
    }

    @Test("A sample an hour before local midnight belongs to that local day")
    func lateSampleStaysOnItsLocalDay() {
        let planned = plan([sample(hour: 23, 83.4)])

        #expect(planned.count == 1)
        #expect(planned[0].dateKey == "2026-09-12")
    }

    @Test("Samples on different days each produce a row, in date order")
    func multipleDaysAreOrdered() {
        let planned = plan([
            sample(day: 14, hour: 7, 82.9),
            sample(day: 10, hour: 7, 83.4),
            sample(day: 12, hour: 7, 83.1),
        ])

        #expect(planned.map(\.dateKey) == ["2026-09-10", "2026-09-12", "2026-09-14"])
    }

    // MARK: - Precedence

    /// The check that matters most: a number the user typed is never replaced.
    @Test("A manual weigh-in is never overwritten")
    func manualWins() {
        let planned = plan(
            [sample(hour: 7, 85.0)],
            existing: [existing(83.4, source: .manual)]
        )

        #expect(planned.isEmpty)
    }

    @Test("An unchanged Health row is not rewritten")
    func unchangedHealthRowIsSkipped() {
        let planned = plan(
            [sample(hour: 7, 83.4)],
            existing: [existing(83.4, source: .healthKit)]
        )

        #expect(planned.isEmpty)
    }

    @Test("A changed Health row is rewritten")
    func changedHealthRowIsPlanned() {
        let planned = plan(
            [sample(hour: 7, 84.0)],
            existing: [existing(83.4, source: .healthKit)]
        )

        #expect(planned.count == 1)
        #expect(planned[0].weightKg == 84.0)
        #expect(planned[0].source == .healthKit)
    }

    @Test("A day with no existing row is written from the sample")
    func newDayIsPlanned() {
        let source = sample(hour: 7, minute: 32, 83.4)
        let planned = plan([source])

        #expect(planned.count == 1)
        #expect(planned[0].source == .healthKit)
        // The scale's own timestamp, not the moment of import.
        #expect(planned[0].loggedAt == source.recordedAt)
    }

    @Test("An existing row on another day does not block this one")
    func otherDaysDoNotInterfere() {
        let planned = plan(
            [sample(day: 13, hour: 7, 83.1)],
            existing: [existing(day: 12, 83.4, source: .manual)]
        )

        #expect(planned.map(\.dateKey) == ["2026-09-13"])
    }

    // MARK: - Plausibility

    @Test("An implausibly light sample is rejected, not clamped")
    func lightSampleRejected() {
        let planned = plan([sample(hour: 7, 4.2)])

        #expect(planned.isEmpty)
    }

    @Test("An implausibly heavy sample is rejected, not clamped")
    func heavySampleRejected() {
        let planned = plan([sample(hour: 7, 420)])

        #expect(planned.isEmpty)
    }

    /// A rejected early sample must not shadow a good later one on the same day.
    @Test("A rejected sample does not claim the day")
    func rejectedSampleDoesNotClaimTheDay() {
        let planned = plan([
            sample(hour: 6, 4.2),
            sample(hour: 8, 83.4),
        ])

        #expect(planned.count == 1)
        #expect(planned[0].weightKg == 83.4)
    }

    // MARK: - Degenerate input

    @Test("No samples yields no writes")
    func emptySamples() {
        #expect(plan([], existing: [existing(83.4, source: .manual)]).isEmpty)
    }

    @Test("Weights are rounded for storage the same way a manual weigh-in is")
    func weightIsRounded() {
        let planned = plan([sample(hour: 7, 83.4567)])

        #expect(planned[0].weightKg == BodyWeight.roundedForStorage(83.4567))
    }
}
