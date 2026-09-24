//
//  HealthSyncCopyTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// The row that said "Connected" while iOS had refused the read. These guard the
/// rule that replaced it: On means the last read found a weight, and nothing
/// characterises a permission iOS does not report.
@Suite("HealthSyncCopy")
struct HealthSyncCopyTests {

    // MARK: - status

    @Test("Status never renders as a granted connection")
    func statusNeverClaimsConnected() {
        let all = [
            HealthSyncCopy.status(isConnected: true, isSyncing: false),
            HealthSyncCopy.status(isConnected: false, isSyncing: false),
            HealthSyncCopy.status(isConnected: true, isSyncing: true),
        ]

        for status in all {
            #expect(!status.localizedCaseInsensitiveContains("connect"))
        }
    }

    @Test("Status is On or Off")
    func statusReflectsLastRead() {
        #expect(HealthSyncCopy.status(isConnected: true, isSyncing: false) == "On")
        #expect(HealthSyncCopy.status(isConnected: false, isSyncing: false) == "Off")
    }

    @Test("Syncing outranks both")
    func syncingWins() {
        #expect(HealthSyncCopy.status(isConnected: true, isSyncing: true) == HealthSyncCopy.syncing)
        #expect(HealthSyncCopy.status(isConnected: false, isSyncing: true) == HealthSyncCopy.syncing)
    }

    // MARK: - detail

    @Test("Nothing to report while off or mid-sync")
    func detailStaysSilent() {
        #expect(HealthSyncCopy.detail(isSyncing: false, lastFoundDateKey: nil) == nil)
        #expect(HealthSyncCopy.detail(isSyncing: true, lastFoundDateKey: "2026-09-12") == nil)
    }

    @Test("A found weight is reported by its day")
    func detailForAFoundWeight() throws {
        let detail = try #require(HealthSyncCopy.detail(isSyncing: false, lastFoundDateKey: "2026-09-12"))

        // The month comes from the device locale, as in `TargetsCopyTests`, so
        // check the day number rather than a whole English sentence.
        #expect(detail.contains("12"))
    }

    @Test("A malformed stored key reports nothing")
    func detailForAMalformedKey() {
        #expect(HealthSyncCopy.detail(isSyncing: false, lastFoundDateKey: "not-a-date") == nil)
    }

    // MARK: - settings hint

    /// Words that would characterise an answer iOS never gives us.
    private static let verdictWords = ["denied", "denie", "blocked", "refused", "not allowed"]

    @Test("Both hints name the Settings page and claim no verdict", arguments: [true, false])
    func hintClaimsNoVerdict(isConnected: Bool) {
        let hint = HealthSyncCopy.settingsHint(isConnected: isConnected)

        #expect(!hint.title.isEmpty)
        #expect(hint.message.contains(HealthSyncCopy.settingsPath))
        for word in Self.verdictWords {
            #expect(!hint.title.localizedCaseInsensitiveContains(word))
            #expect(!hint.message.localizedCaseInsensitiveContains(word))
        }
    }

    @Test("Off points at turning Weight on, On at turning it off")
    func hintMatchesTheRow() {
        #expect(HealthSyncCopy.settingsHint(isConnected: false).message.contains("turn on Weight"))
        #expect(HealthSyncCopy.settingsHint(isConnected: true).message.contains("turn off Weight"))
    }
}

/// The service records its outcome from what Health returned, via
/// `dailySamples`, so these pin the two properties that reporting rests on.
@Suite("Health sync outcome")
struct HealthSyncOutcomeTests {
    private let planner = WeighInImportPlanner()
    private let utc = TimeZone(identifier: "UTC")!

    private func sample(_ dayKey: String, _ weightKg: Double) throws -> HealthKitWeightSample {
        HealthKitWeightSample(
            recordedAt: try #require(DateKey.date(from: dayKey, timeZone: utc)),
            weightKg: weightKg
        )
    }

    @Test("The newest day is the greatest key")
    func newestDayIsTheMaxKey() throws {
        let samples = [
            try sample("2026-09-08", 81.4),
            try sample("2026-09-12", 80.9),
            try sample("2026-09-10", 81.1),
        ]

        let newest = planner.dailySamples(from: samples, timeZone: utc).keys.max()
        #expect(newest == "2026-09-12")
    }

    @Test("An implausible reading is not a weight found")
    func catOnTheScaleIsNotAWeight() throws {
        // Alone, this must leave the row Off rather than reporting a day —
        // `plan` would skip it, so reporting it would promise a weigh-in that
        // never appears.
        let samples = [try sample("2026-09-12", 4.0)]

        #expect(planner.dailySamples(from: samples, timeZone: utc).keys.max() == nil)
    }

    @Test("Weights already imported still count as found")
    func unchangedSamplesStillCount() throws {
        let samples = [try sample("2026-09-12", 80.9)]
        let existing = [
            WeighIn(dateKey: "2026-09-12", weightKg: 80.9, loggedAt: .now, source: .healthKit)
        ]

        // `plan` writes nothing — the row must not read that as a failed read.
        #expect(planner.plan(samples: samples, existing: existing, timeZone: utc).isEmpty)
        #expect(planner.dailySamples(from: samples, timeZone: utc).keys.max() == "2026-09-12")
    }
}
