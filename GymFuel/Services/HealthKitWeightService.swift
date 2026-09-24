//
//  HealthKitWeightService.swift
//  GymFuel
//

import Foundation
import HealthKit

/// Reads body mass from Apple Health. **Nothing else, in either direction.**
///
/// The read set is exactly `[bodyMass]` and the share set is empty. No active
/// energy, no workouts, no steps — not as an input and not as displayed
/// context. A burn figure reaching this app is the calorie rebate under a new
/// name, and it corrupts the adaptive engine the trend feeds.
///
/// A protocol, despite there being one query behind it, so
/// `HealthWeightSyncService` can be exercised without a device, an entitlement
/// or an authorization prompt.
/// iOS's answer to "would the sheet appear for body mass?", with its
/// uncertainty kept intact.
///
/// Three cases rather than a `Bool` because the caller clears the user's opt-in
/// on `neverAsked`: collapsing `unknown` into it would disconnect somebody
/// because one query happened to fail. `HealthKitWeightSample` keeps HealthKit
/// out of the sample type for the same reason this keeps it out of the status.
enum HealthAuthorizationRequestState {
    /// iOS states it has never had an answer for `bodyMass`.
    case neverAsked
    /// The sheet has been answered. **Which way is not disclosed.**
    case alreadyAsked
    /// No Health database, or the query failed. Evidence of neither case above.
    case unknown
}

protocol HealthKitWeightReading: Sendable {
    /// `false` on hardware with no Health database. Everything else no-ops.
    var isAvailable: Bool { get }

    /// Whether tapping Connect would still raise the system sheet.
    ///
    /// This is **not** an allowed/denied signal — see the note on
    /// `HealthKitWeightService`.
    func authorizationRequestState() async -> HealthAuthorizationRequestState

    func requestAuthorization() async throws

    /// Ascending by sample start date. Empty is a normal, expected result.
    func bodyMassSamples(from start: Date, through end: Date) async throws -> [HealthKitWeightSample]
}

/// - Important: **iOS never reports a denied *read*.** `authorizationStatus(for:)`
///   describes write permission only, and a denied read is indistinguishable
///   from an empty Health database — both return zero samples. So no screen in
///   this app may say "you denied this": an empty import is the normal case,
///   and the most that can honestly be offered is a pointer to the Health app.
///   `getRequestStatusForAuthorization` narrows this only to "would the prompt
///   appear", which is what `authorizationRequestState` returns.
final class HealthKitWeightService: @unchecked Sendable {
    /// How far back an import reaches.
    ///
    /// Mirrors `StatsViewModel.trendWindowDays` — the chart never draws further
    /// back than this, so importing further back writes rows nobody can see.
    /// Kept as its own constant rather than reaching into a view model from a
    /// service; if one moves, move the other.
    static let importWindowDays = 90

    private let store = HKHealthStore()

    private var bodyMassType: HKQuantityType {
        HKQuantityType(.bodyMass)
    }
}

extension HealthKitWeightService: HealthKitWeightReading {
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func authorizationRequestState() async -> HealthAuthorizationRequestState {
        guard isAvailable else { return .unknown }

        let status: HKAuthorizationRequestStatus? = try? await withCheckedThrowingContinuation { continuation in
            store.getRequestStatusForAuthorization(toShare: [], read: [bodyMassType]) { status, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: status)
                }
            }
        }

        switch status {
        case .shouldRequest: return .neverAsked
        case .unnecessary: return .alreadyAsked
        default: return .unknown
        }
    }

    func requestAuthorization() async throws {
        guard isAvailable else { return }
        try await store.requestAuthorization(toShare: [], read: [bodyMassType])
    }

    func bodyMassSamples(from start: Date, through end: Date) async throws -> [HealthKitWeightSample] {
        guard isAvailable else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [.strictStartDate])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let kilograms = HKUnit.gramUnit(with: .kilo)

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HealthKitWeightSample], Error>) in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                // Value types only across the continuation — nothing
                // HealthKit-shaped escapes this closure, which is what keeps
                // the `@unchecked Sendable` above honest.
                let mapped = (samples as? [HKQuantitySample] ?? []).map { sample in
                    HealthKitWeightSample(
                        recordedAt: sample.startDate,
                        weightKg: sample.quantity.doubleValue(for: kilograms)
                    )
                }
                continuation.resume(returning: mapped)
            }

            store.execute(query)
        }
    }
}
