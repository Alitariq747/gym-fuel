//
//  WeighInViewModel.swift
//  GymFuel
//

import Foundation
import SwiftUI

/// Owns the one write that the whole trend rests on.
///
/// A weigh-in touches two documents — `weighIns/{dateKey}` and the profile's
/// `weightKg`. They are written **sequentially, history first**, not in a batch.
///
/// The only failure worth engineering against is *profile written, weigh-in
/// not*: targets would move on a data point that is not in the history, and the
/// hole is silent. Writing the weigh-in first and throwing on its failure makes
/// that state unreachable. The opposite partial state — weigh-in stored, profile
/// weight stale — leaves the trend correct, self-heals on the next weigh-in, and
/// is retryable. A batch would fail atomically, so a rules rejection on the
/// profile half would discard a *correct* weigh-in, which is worse.
///
/// Both writes are `setData(merge:)` on a fixed key, so they are idempotent and
/// "just retry" is a complete recovery story.
@MainActor
final class WeighInViewModel: ObservableObject {
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?

    private let weighInService: WeighInService
    private let profileService: FirebaseUserProfileService
    private let networkMonitor: NetworkMonitoring

    init(
        weighInService: WeighInService = FirebaseWeighInService(),
        profileService: FirebaseUserProfileService = .shared,
        networkMonitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.weighInService = weighInService
        self.profileService = profileService
        self.networkMonitor = networkMonitor
    }

    func clearError() {
        errorMessage = nil
    }

    /// - Returns: `true` when the caller should dismiss.
    func recordWeighIn(
        userId: String,
        weightKg: Double,
        now: Date = .now,
        timeZone: TimeZone = .current
    ) async -> Bool {
        // `ProfileView.draftBinding`'s fallback builds a profile with an empty
        // id. Writing that would create `users//weighIns/...`.
        guard !userId.isEmpty else {
            errorMessage = "We couldn't tell which account to save this to. Please try again."
            return false
        }

        let rounded = BodyWeight.roundedForStorage(weightKg)
        guard rounded > 0 else {
            errorMessage = "Please select a valid weight."
            return false
        }

        isSaving = true
        defer { isSaving = false }
        errorMessage = nil

        let weighIn = WeighIn(
            recordedAt: now,
            weightKg: rounded,
            source: .manual,
            timeZone: timeZone
        )

        // Firestore's completion fires only on server acknowledgement, so
        // awaiting a write while offline never resumes — the sheet would spin
        // forever with no error. Write into the local cache instead and let it
        // sync. Same reason `saveEntryLocally` exists on the log entry service.
        guard networkMonitor.isConnected else {
            do {
                try weighInService.saveWeighInLocally(weighIn, for: userId)
                profileService.updateWeightLocally(rounded, for: userId)
                FirebaseTelemetryService.logWeighInEvent("saved", source: weighIn.source.rawValue)
                return true
            } catch {
                errorMessage = AppErrorMessage.message(
                    for: error,
                    fallback: "We couldn't save your weigh-in. Please try again."
                )
                return false
            }
        }

        do {
            try await weighInService.saveWeighIn(weighIn, for: userId)
            try await profileService.updateWeight(rounded, for: userId)
            FirebaseTelemetryService.logWeighInEvent("saved", source: weighIn.source.rawValue)
            return true
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't save your weigh-in. Please try again."
            )
            FirebaseTelemetryService.recordNonFatal(
                error,
                reason: "weigh_in_save_failed",
                metadata: ["dateKey": weighIn.dateKey]
            )
            return false
        }
    }
}
