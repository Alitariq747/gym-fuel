//
//  WeightViewModel.swift
//  GymFuel
//

import Foundation

/// The Weight screen's state: every weigh-in, and the same as a chart series.
/// The goal comes from the profile, not from here.
@MainActor
final class WeightViewModel: ObservableObject {
    /// Ascending by day. Nil until the first read answers, so the screen never
    /// says "no weigh-ins" before it knows.
    @Published private(set) var weighIns: [WeighIn]?
    @Published private(set) var series: WeightSeries = .empty
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

    /// All of them, so the chart's All means all; 30d and 90d only narrow the view.
    func load(userId: String, timeZone: TimeZone = .current) async {
        guard !userId.isEmpty else { return }

        do {
            let fetched = try await weighInService.fetchAllWeighIns(for: userId)
            weighIns = fetched
            series = WeightSeries(weighIns: fetched, timeZone: timeZone)
            errorMessage = nil
        } catch {
            FirebaseTelemetryService.recordNonFatal(error, reason: "weigh_in_fetch_failed")
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't load your weigh-ins. Please try again."
            )
        }
    }

    /// Deletes a typed weigh-in, then moves the profile's weight back when it was
    /// the newest. History first, as `WeighInViewModel.recordWeighIn` writes; if
    /// the second write fails, the weight shown heals at the next weigh-in.
    ///
    /// - Returns: the weight the profile now shows, when it moved.
    func delete(_ weighIn: WeighIn, userId: String) async -> Double? {
        let weighIns = self.weighIns ?? []
        guard !userId.isEmpty, WeighInDeletion.canDelete(weighIn, among: weighIns) else { return nil }
        let movedWeightKg = WeighInDeletion.profileWeight(afterDeleting: weighIn, among: weighIns)

        do {
            // Awaiting a write offline never resumes, so offline goes to the cache.
            if networkMonitor.isConnected {
                try await weighInService.deleteWeighIn(dateKey: weighIn.dateKey, for: userId)
                if let movedWeightKg { try await profileService.updateWeight(movedWeightKg, for: userId) }
            } else {
                weighInService.deleteWeighInLocally(dateKey: weighIn.dateKey, for: userId)
                if let movedWeightKg { profileService.updateWeightLocally(movedWeightKg, for: userId) }
            }
            FirebaseTelemetryService.logWeighInEvent("deleted", source: weighIn.source.rawValue)
        } catch {
            FirebaseTelemetryService.recordNonFatal(
                error,
                reason: "weigh_in_delete_failed",
                metadata: ["dateKey": weighIn.dateKey]
            )
            // Reload first: a successful load clears the message.
            await load(userId: userId)
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't delete that weigh-in. Please try again."
            )
            return nil
        }

        await load(userId: userId)
        return movedWeightKg
    }
}
