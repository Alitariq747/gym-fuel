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

    /// Whether a sync has finished since the user opted in, and the newest day
    /// Health supplied a usable weight for.
    ///
    /// The Health row has no authorization to render — iOS reports none — so it
    /// renders this instead: what the last read actually returned. `nil` after a
    /// completed sync is the one statement that stays true whether the read was
    /// refused or the database is simply empty.
    @Published private(set) var hasSynced: Bool
    @Published private(set) var lastFoundDateKey: String?

    private static let connectedKey = "lifteats.health.weightSyncEnabled"
    private static let hasSyncedKey = "lifteats.health.hasSynced"
    private static let lastFoundKey = "lifteats.health.lastFoundDateKey"

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
        self.hasSynced = defaults.bool(forKey: Self.hasSyncedKey)
        self.lastFoundDateKey = defaults.string(forKey: Self.lastFoundKey)
    }

    /// `false` on hardware with no Health database. Every surface hides itself
    /// rather than offering something that cannot work.
    var isAvailable: Bool {
        healthService.isAvailable
    }

    /// Whether tapping Connect would still raise the system sheet.
    ///
    /// Status only, and **not** an allowed/denied signal — see the note on
    /// `HealthKitWeightService`.
    func willAskForAccess() async -> Bool {
        await healthService.authorizationRequestState() == .neverAsked
    }

    /// Raises the system sheet and records the opt-in. Safe to call when already
    /// connected — iOS shows its sheet at most once per type, so it then returns
    /// without showing anything.
    ///
    /// Separate from `connect` because the onboarding step runs before an
    /// account exists: there is no uid to import against yet, and the sheet
    /// needs none. `RootView.importHealthWeight` picks the import up as soon as
    /// a uid appears.
    func requestAccess() async {
        guard isAvailable else { return }

        do {
            try await healthService.requestAuthorization()
        } catch {
            FirebaseTelemetryService.recordNonFatal(error, reason: "health_authorization_failed")
            return
        }

        // Connected means "opted in", not "granted" — a denied read is
        // invisible to us, so there is nothing else this flag could mean.
        setConnected(true)
        FirebaseTelemetryService.logWeighInEvent("health_connected", source: WeighInSource.healthKit.rawValue)
    }

    /// Requests read access, then imports.
    ///
    /// - Returns: the weight the profile should now show, if the import moved it.
    @discardableResult
    func connect(userId: String) async -> Double? {
        await requestAccess()
        guard isConnected else { return nil }

        return await sync(userId: userId)
    }

    /// The foreground path. No-ops unless the user has opted in.
    ///
    /// Drops a stale opt-in before syncing. `requestAuthorization` cannot report
    /// a refusal, so `connect` records one for a user who declined, and the flag
    /// then outlives reinstalls over the top. `.neverAsked` settles that case.
    /// It does **not** settle a read revoked in the Health app — nothing does —
    /// which is why the row describes what the last sync found rather than a
    /// connection state.
    @discardableResult
    func syncIfConnected(userId: String) async -> Double? {
        guard isConnected else { return nil }

        // Status only. Re-prompting without a tap is what App Review 5.1.1(iv)
        // forbids, and iOS refuses to show the sheet twice regardless.
        if await healthService.authorizationRequestState() == .neverAsked {
            setConnected(false)
            return nil
        }

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

        // Recorded from what Health returned, not from `planned`: a sync that
        // finds only weights already held is a *working* connection, and the row
        // must not then say nothing was found. Via `dailySamples` so the
        // planner's plausibility rule stays the single one — a lone 4 kg reading
        // is not a weight found.
        recordSyncOutcome(lastFound: planner.dailySamples(from: samples).keys.max())

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

    /// Keeps `users/{uid}.weightKg` on the newest measurement, so the weight the
    /// app shows matches the weigh-in history. It never changes the saved targets.
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

        // Disconnecting discards the last outcome so a later reconnect reports
        // its own read rather than one from before the gap.
        if !connected {
            recordSyncOutcome(lastFound: nil, synced: false)
        }
    }

    private func recordSyncOutcome(lastFound dateKey: String?, synced: Bool = true) {
        defaults.set(synced, forKey: Self.hasSyncedKey)
        if let dateKey {
            defaults.set(dateKey, forKey: Self.lastFoundKey)
        } else {
            defaults.removeObject(forKey: Self.lastFoundKey)
        }
        hasSynced = synced
        lastFoundDateKey = dateKey
    }
}
