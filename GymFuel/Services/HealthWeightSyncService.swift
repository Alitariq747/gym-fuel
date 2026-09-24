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
    @Published private(set) var isSyncing = false

    /// The newest day the last sync found a usable weight for.
    @Published private(set) var lastFoundDateKey: String?

    /// On only once a read has returned a weight — iOS never reports a refused
    /// read, which looks exactly like an empty Health database.
    var isConnected: Bool { lastFoundDateKey != nil }

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

    /// Raises the system sheet. iOS shows it at most once per type, so a later
    /// call returns without showing anything.
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

        FirebaseTelemetryService.logWeighInEvent("health_connected", source: WeighInSource.healthKit.rawValue)
    }

    /// Requests read access, then imports.
    ///
    /// - Returns: the weight the profile should now show, if the import moved it.
    @discardableResult
    func connect(userId: String) async -> Double? {
        await requestAccess()
        return await syncIfAsked(userId: userId)
    }

    /// The foreground path. Syncs whenever iOS has asked, whichever way the user
    /// answered, so a read switched on later in Settings arrives on its own.
    @discardableResult
    func syncIfAsked(userId: String) async -> Double? {
        // Status only. Re-prompting without a tap is what App Review 5.1.1(iv)
        // forbids, and iOS refuses to show the sheet twice regardless.
        switch await healthService.authorizationRequestState() {
        case .alreadyAsked:
            return await sync(userId: userId)
        case .neverAsked:
            recordSyncOutcome(lastFound: nil)
            return nil
        case .unknown:
            return nil
        }
    }

    /// Whether Health returns a usable weight right now. Needs no account, so
    /// onboarding can check before sign-up.
    func canReadWeights() async -> Bool {
        guard let window = importWindow(),
              let samples = try? await healthService.bodyMassSamples(from: window.start, through: window.end)
        else { return false }

        return !planner.dailySamples(from: samples).isEmpty
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
        // must not then read Off. Via `dailySamples` so the
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

    private func recordSyncOutcome(lastFound dateKey: String?) {
        if let dateKey {
            defaults.set(dateKey, forKey: Self.lastFoundKey)
        } else {
            defaults.removeObject(forKey: Self.lastFoundKey)
        }
        lastFoundDateKey = dateKey
    }
}
