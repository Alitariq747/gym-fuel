//
//  WeightViewModel.swift
//  GymFuel
//

import Foundation

/// The Weight screen's state: the weigh-ins in view and the trend through them.
/// The plan line comes from the profile, not from here.
@MainActor
final class WeightViewModel: ObservableObject {
    /// How far past today the chart runs, so a plan started today still shows its
    /// line (decided 19 September). The window back is `StatsViewModel.trendWindowDays`.
    static let lookaheadDays = 28

    /// Ascending by day. Nil until the first read answers, so the screen never
    /// says "no weigh-ins" before it knows.
    @Published private(set) var weighIns: [WeighIn]?
    @Published private(set) var series: WeightTrendSeries = .empty
    @Published private(set) var errorMessage: String?

    private let weighInService: WeighInService
    private let profileService: FirebaseUserProfileService
    private let networkMonitor: NetworkMonitoring
    private let weightTrendCalculator: WeightTrendCalculator

    init(
        weighInService: WeighInService = FirebaseWeighInService(),
        profileService: FirebaseUserProfileService = .shared,
        networkMonitor: NetworkMonitoring = NetworkMonitor.shared,
        weightTrendCalculator: WeightTrendCalculator = WeightTrendCalculator()
    ) {
        self.weighInService = weighInService
        self.profileService = profileService
        self.networkMonitor = networkMonitor
        self.weightTrendCalculator = weightTrendCalculator
    }

    /// The same 90 days as the Week card and the Health import, then four weeks
    /// ahead. Anchored to the start of today, so it holds still between redraws.
    func chartDomain(now: Date = .now, calendar: Calendar = .current) -> ClosedRange<Date> {
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -StatsViewModel.trendWindowDays, to: today) ?? today
        let end = calendar.date(byAdding: .day, value: Self.lookaheadDays, to: today) ?? today
        return start...end
    }

    func load(userId: String, now: Date = .now, calendar: Calendar = .current, timeZone: TimeZone = .current) async {
        guard !userId.isEmpty else { return }

        let fromKey = DateKey.key(for: chartDomain(now: now, calendar: calendar).lowerBound, timeZone: timeZone)
        let throughKey = DateKey.key(for: now, timeZone: timeZone)

        do {
            let fetched = try await weighInService.fetchWeighIns(for: userId, fromKey: fromKey, throughKey: throughKey)
            weighIns = fetched
            series = weightTrendCalculator.series(from: fetched, timeZone: timeZone)
            errorMessage = nil
        } catch {
            FirebaseTelemetryService.recordNonFatal(
                error,
                reason: "weigh_in_fetch_failed",
                metadata: ["fromKey": fromKey, "throughKey": throughKey]
            )
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
