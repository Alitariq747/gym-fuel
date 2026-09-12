//
//  WeighInImportPlanner.swift
//  GymFuel
//

import Foundation

/// One body-mass reading, stripped of HealthKit.
///
/// The import's rules are the part that can be silently wrong, so they live in
/// a pure type that knows nothing about `HKSampleQuery` and can be tested
/// without a device or an authorization prompt.
struct HealthKitWeightSample: Equatable, Sendable {
    /// The sample's own `startDate` — when the user actually stood on the
    /// scale, not when we read it.
    let recordedAt: Date
    let weightKg: Double
}

/// Decides which Apple Health samples become `weighIns` rows.
///
/// Pure arithmetic and comparison, no I/O — the same posture as
/// `WeightTrendCalculator`, and for the same reason: every rule below has a
/// failure mode that looks like correct data.
struct WeighInImportPlanner {
    init() {}

    /// The sample that owns each local day: the **earliest** one.
    ///
    /// Health may hold several readings for a date; `weighIns/{yyyy-MM-dd}` is
    /// one row per day, so one has to win. Morning is the trending convention
    /// and it is what `EditWeightSheet` already tells the user to do — an
    /// evening reading after a day of food, water and salt sits a kilo or two
    /// above the morning one, and feeding that to the EMA treats a full stomach
    /// as a direction.
    func dailySamples(
        from samples: [HealthKitWeightSample],
        timeZone: TimeZone = .current
    ) -> [String: HealthKitWeightSample] {
        var earliest: [String: HealthKitWeightSample] = [:]

        for sample in samples where isPlausible(sample) {
            let dateKey = DateKey.key(for: sample.recordedAt, timeZone: timeZone)
            guard !dateKey.isEmpty else { continue }

            if let existing = earliest[dateKey], existing.recordedAt <= sample.recordedAt {
                continue
            }
            earliest[dateKey] = sample
        }

        return earliest
    }

    /// The rows worth writing, given what the `weighIns` collection already
    /// holds for the same window. Ascending by day.
    ///
    /// Three rules, in order:
    ///
    /// 1. **A manual weigh-in is never overwritten.** The user typed that
    ///    number deliberately; a scale syncing at 9pm silently replacing the
    ///    7am correction is the failure `build-order.md` Step 13 warns about.
    /// 2. **An unchanged Health row is not rewritten.** A steady-state
    ///    foreground sync therefore writes nothing at all, which is what makes
    ///    running this on every app open cheap.
    /// 3. Everything else is written with `source: .healthKit`.
    func plan(
        samples: [HealthKitWeightSample],
        existing: [WeighIn],
        timeZone: TimeZone = .current
    ) -> [WeighIn] {
        let candidates = dailySamples(from: samples, timeZone: timeZone)
        guard !candidates.isEmpty else { return [] }

        var existingByDay: [String: WeighIn] = [:]
        for weighIn in existing {
            existingByDay[weighIn.dateKey] = weighIn
        }

        var planned: [WeighIn] = []
        planned.reserveCapacity(candidates.count)

        for (dateKey, sample) in candidates {
            let weightKg = BodyWeight.roundedForStorage(sample.weightKg)

            if let current = existingByDay[dateKey] {
                // Rule 1.
                guard current.source == .healthKit else { continue }
                // Rule 2.
                guard current.weightKg != weightKg else { continue }
            }

            planned.append(
                WeighIn(
                    dateKey: dateKey,
                    weightKg: weightKg,
                    loggedAt: sample.recordedAt,
                    source: .healthKit
                )
            )
        }

        // Lexicographic order on zero-padded "yyyy-MM-dd" **is** chronological.
        return planned.sorted { $0.dateKey < $1.dateKey }
    }

    /// Rejects readings outside the range the app's own pickers offer.
    ///
    /// **Rejected, not clamped.** A 4 kg row is somebody's cat on the scale or a
    /// bad third-party import; pulling it up to 30 would invent a measurement
    /// and draw it as fact. Skipping just leaves a gap, which the trend already
    /// handles by design.
    private func isPlausible(_ sample: HealthKitWeightSample) -> Bool {
        sample.weightKg >= BodyWeight.minimumKilograms
            && sample.weightKg <= BodyWeight.maximumKilograms
    }
}
