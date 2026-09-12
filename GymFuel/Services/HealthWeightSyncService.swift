//
//  HealthWeightSyncService.swift
//  GymFuel
//

import Foundation
import SwiftUI

/// Pulls Apple Health body mass into the `weighIns` collection.
///
/// The engine's scarcest input is a *second* weigh-in. A user with a smart
/// scale already produces one every morning; this closes the gap between that
/// measurement and the trend without either of them opening the app for it.
///
/// An `ObservableObject` in the environment rather than a `shared` singleton
/// like `ReminderService`: the Settings row renders from `isConnected` and
/// `isSyncing`, so the state has to be published somewhere SwiftUI observes.
/// Held by `GymFuelApp` and injected the way `SubscriptionViewModel` is.
@MainActor
final class HealthWeightSyncService: ObservableObject {
    /// Whether the user has opted in. Not an authorization state — iOS will not
    /// tell us that for reads — just a record that they tapped Connect and we
    /// may therefore sync on foreground.
    @Published private(set) var isConnected: Bool

    @Published private(set) var isSyncing = false

    private static let connectedKey = "lifteats.health.weightSyncEnabled"

    private let healthService: HealthKitWeightReading
    private let weighInService: WeighInService
    private let profileService: FirebaseUserProfileService
    private let networkMonitor: NetworkMonitoring
    private let planner: WeighInImportPlanner
    private let defaults: UserDefaults

    init(
        healthService: HealthKitWeightReading = HealthKitWeightService(),
        weighInService: WeighInService = FirebaseWeighInService(),
        profileService: FirebaseUserProfileService = .shared,
        networkMonitor: NetworkMonitoring = NetworkMonitor.shared,
        planner: WeighInImportPlanner = WeighInImportPlanner(),
        defaults: UserDefaults = .standard
    ) {
        self.healthService = healthService
        self.weighInService = weighInService
        self.profileService = profileService
        self.networkMonitor = networkMonitor
        self.planner = planner
        self.defaults = defaults
        self.isConnected = defaults.bool(forKey: Self.connectedKey)
    }

    /// `false` on hardware with no Health database. Every surface hides itself
    /// rather than offering something that cannot work.
    var isAvailable: Bool {
        healthService.isAvailable
    }

    /// Requests read access, then imports. Safe to call when already connected —
    /// iOS shows its sheet at most once per type, so this degrades to a sync.
    ///
    /// - Returns: the weight the profile should now show, if the import moved it.
    @discardableResult
    func connect(userId: String) async -> Double? {
        guard isAvailable else { return nil }

        do {
            try await healthService.requestAuthorization()
        } catch {
            FirebaseTelemetryService.recordNonFatal(error, reason: "health_authorization_failed")
            return nil
        }

        // Connected means "opted in", not "granted" — a denied read is
        // invisible to us, so there is nothing else this flag could mean.
        setConnected(true)
        FirebaseTelemetryService.logWeighInEvent("health_connected", source: WeighInSource.healthKit.rawValue)

        return await sync(userId: userId)
    }

    /// The foreground path. No-ops unless the user has opted in.
    @discardableResult
    func syncIfConnected(userId: String) async -> Double? {
        guard isConnected else { return nil }
        return await sync(userId: userId)
    }

    func disconnect() {
        setConnected(false)
    }

    // MARK: - The import

    /// - Returns: the weight the profile should now show, or `nil` if nothing
    ///   changed. The caller applies it via `UserProfileViewModel.applyWeighIn`;
    ///   this service deliberately does not know that type exists.
    private func sync(userId: String) async -> Double? {
        guard isAvailable, !isSyncing, !userId.isEmpty else { return nil }

        guard let window = importWindow() else { return nil }

        isSyncing = true
        defer { isSyncing = false }

        let samples: [HealthKitWeightSample]
        let existing: [WeighIn]

        do {
            samples = try await healthService.bodyMassSamples(from: window.start, through: window.end)
            // This read *is* the precedence check — it is what tells the planner
            // which days already carry a manual weigh-in.
            existing = try await weighInService.fetchWeighIns(
                for: userId,
                fromKey: window.fromKey,
                throughKey: window.throughKey
            )
        } catch {
            FirebaseTelemetryService.recordNonFatal(error, reason: "health_weight_sync_failed")
            return nil
        }

        let planned = planner.plan(samples: samples, existing: existing)
        guard !planned.isEmpty else { return nil }

        // Written into Firestore's local cache without awaiting server
        // acknowledgement. `setData(_:merge:completion:)` fires only on
        // acknowledgement, so awaiting one per imported day would hang the
        // whole foreground path while offline — the reason `saveWeighInLocally`
        // exists, and the same branch `WeighInViewModel` takes. The cost is
        // that a failed import is silent; the next foreground recomputes an
        // identical plan, so it self-heals.
        var written = 0
        for weighIn in planned {
            do {
                try weighInService.saveWeighInLocally(weighIn, for: userId)
                written += 1
            } catch {
                FirebaseTelemetryService.recordNonFatal(
                    error,
                    reason: "health_weigh_in_write_failed",
                    metadata: ["dateKey": weighIn.dateKey]
                )
            }
        }

        guard written > 0 else { return nil }

        // Action and source only. A weight value must never reach an analytics
        // payload — that is a removal trigger, not a rejection.
        FirebaseTelemetryService.logWeighInEvent("imported", source: WeighInSource.healthKit.rawValue)

        return await applyLatestWeight(userId: userId, existing: existing, planned: planned)
    }

    /// Keeps `users/{uid}.weightKg` on the newest measurement, so the BMR in
    /// `MacroTargetCalculator` does not drift away from the weigh-in history.
    ///
    /// An import **is** a weigh-in, which is the only thing permitted to move
    /// stored weight.
    private func applyLatestWeight(
        userId: String,
        existing: [WeighIn],
        planned: [WeighIn]
    ) async -> Double? {
        let newest = (existing + planned).max { $0.dateKey < $1.dateKey }
        // Only an imported row is news; if the newest day is still a manual
        // weigh-in, the profile already agrees with it.
        guard let newest, newest.source == .healthKit else { return nil }

        guard networkMonitor.isConnected else {
            profileService.updateWeightLocally(newest.weightKg, for: userId)
            return newest.weightKg
        }

        do {
            try await profileService.updateWeight(newest.weightKg, for: userId)
            return newest.weightKg
        } catch {
            FirebaseTelemetryService.recordNonFatal(error, reason: "health_profile_weight_update_failed")
            return nil
        }
    }

    private func importWindow(
        calendar: Calendar = .current,
        timeZone: TimeZone = .current,
        now: Date = .now
    ) -> (start: Date, end: Date, fromKey: String, throughKey: String)? {
        guard let start = calendar.date(
            byAdding: .day,
            value: -HealthKitWeightService.importWindowDays,
            to: now
        ) else { return nil }

        return (
            start,
            now,
            DateKey.key(for: start, timeZone: timeZone),
            DateKey.key(for: now, timeZone: timeZone)
        )
    }

    private func setConnected(_ connected: Bool) {
        defaults.set(connected, forKey: Self.connectedKey)
        isConnected = connected
    }
}
