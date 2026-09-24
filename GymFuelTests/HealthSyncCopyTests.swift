//
//  HealthSyncCopyTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// The row that said "Connected" while iOS had refused the read. These guard the
/// rule that replaced it: say what the user chose and what the last read found,
/// and never characterise a permission iOS does not report.
@Suite("HealthSyncCopy")
struct HealthSyncCopyTests {

    // MARK: - status

    @Test("Opting in never renders as a granted connection")
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

    @Test("Status names the user's own choice")
    func statusReflectsOptIn() {
        #expect(HealthSyncCopy.status(isConnected: true, isSyncing: false) == "On")
        #expect(HealthSyncCopy.status(isConnected: false, isSyncing: false) == "Off")
    }

    @Test("Syncing outranks both")
    func syncingWins() {
        #expect(HealthSyncCopy.status(isConnected: true, isSyncing: true) == HealthSyncCopy.syncing)
        #expect(HealthSyncCopy.status(isConnected: false, isSyncing: true) == HealthSyncCopy.syncing)
    }

    // MARK: - detail

    @Test("Nothing to report until a sync has finished")
    func detailWaitsForASync() {
        #expect(HealthSyncCopy.detail(
            isConnected: true, isSyncing: false, hasSynced: false, lastFoundDateKey: nil
        ) == nil)

        // Off, and mid-sync, both stay silent even with a result on file.
        #expect(HealthSyncCopy.detail(
            isConnected: false, isSyncing: false, hasSynced: true, lastFoundDateKey: "2026-09-12"
        ) == nil)
        #expect(HealthSyncCopy.detail(
            isConnected: true, isSyncing: true, hasSynced: true, lastFoundDateKey: "2026-09-12"
        ) == nil)
    }

    @Test("A completed read that found nothing says so, and blames nobody")
    func detailForAnEmptyRead() throws {
        let detail = try #require(HealthSyncCopy.detail(
            isConnected: true, isSyncing: false, hasSynced: true, lastFoundDateKey: nil
        ))

        #expect(detail == HealthSyncCopy.nothingFound)
        // A refused read and an empty database are indistinguishable, so the
        // sentence may not imply either one.
        for word in Self.verdictWords {
            #expect(!detail.localizedCaseInsensitiveContains(word))
        }
    }

    /// Words that would characterise an answer iOS never gives us.
    ///
    /// "permission" is allowed only where the copy describes iOS's *sheet*
    /// rather than its outcome, which is why the alert is checked separately.
    private static let verdictWords = ["denied", "denie", "blocked", "refused", "permission", "not allowed"]

    @Test("The asks-once alert states an iOS behaviour, not a verdict")
    func alertClaimsNoVerdict() {
        let body = HealthSyncCopy.asksOnceBody

        for word in ["denied", "denie", "blocked", "refused", "not allowed"] {
            #expect(!body.localizedCaseInsensitiveContains(word))
        }
        // It has to be actionable: name the place the switch actually lives.
        #expect(body.contains("Health"))
        #expect(!HealthSyncCopy.asksOnceTitle.isEmpty)
        // No trailing backslash or stray newline from the multi-line literal.
        #expect(!body.contains("\n"))
        #expect(!body.contains("\\"))
    }

    @Test("A found weight is reported by its day")
    func detailForAFoundWeight() throws {
        let detail = try #require(HealthSyncCopy.detail(
            isConnected: true, isSyncing: false, hasSynced: true, lastFoundDateKey: "2026-09-12"
        ))

        #expect(detail != HealthSyncCopy.nothingFound)
        // The month comes from the device locale, as in `TargetsCopyTests`, so
        // check the day number rather than a whole English sentence.
        #expect(detail.contains("12"))
    }

    @Test("A malformed stored key degrades to the empty-read sentence")
    func detailForAMalformedKey() {
        #expect(HealthSyncCopy.detail(
            isConnected: true, isSyncing: false, hasSynced: true, lastFoundDateKey: "not-a-date"
        ) == HealthSyncCopy.nothingFound)
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
        // Alone, this must leave the row saying nothing was found rather than
        // reporting a day — `plan` would skip it, so reporting it would promise
        // a weigh-in that never appears.
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
