//
//  TargetWeight.swift
//  GymFuel
//

import Foundation

/// Which target weights Settings accepts.
///
/// Pure, so the limits are testable without a view. The rules (`build-order.md`
/// Step 4, decision 10): below today's weight for Lose fat, above it for Gain,
/// never in the underweight range, and Maintain has none.
///
/// Checked only when the user **sets** a target or changes goal — never again as
/// weight moves. Reaching the target is the check-in's business, not a reason to
/// drop it.
enum TargetWeight {
    /// The WHO lower limit of the healthy BMI range. Sources method 06 cites it.
    static let minimumBMI: Double = 18.5

    /// The smallest step the pickers move in, in kilograms.
    static let stepKg: Double = 0.1

    /// The lowest weight outside the underweight range at this height.
    static func lowestHealthyKg(heightCm: Double) -> Double {
        let heightM = heightCm / 100
        return minimumBMI * heightM * heightM
    }

    /// The target weights allowed for this goal, or `nil` when there are none.
    static func allowedRange(
        goal: GoalType?,
        currentWeightKg: Double?,
        heightCm: Double?
    ) -> ClosedRange<Double>? {
        guard let goal,
              let currentWeightKg, currentWeightKg > 0,
              let heightCm, heightCm > 0
        else { return nil }

        let healthyFloor = lowestHealthyKg(heightCm: heightCm)
        let lower: Double
        let upper: Double

        switch goal {
        case .maintain:
            return nil
        case .cut:
            lower = max(healthyFloor, BodyWeight.minimumKilograms)
            upper = min(currentWeightKg - stepKg, BodyWeight.maximumKilograms)
        case .leanBulk:
            lower = max(currentWeightKg + stepKg, healthyFloor, BodyWeight.minimumKilograms)
            upper = BodyWeight.maximumKilograms
        }

        // Bounds at storage precision, rounded inward, so a value rounded by
        // `BodyWeight.roundedForStorage` can never fall just outside its own
        // range. The 1e-6 nudge stops 79.9 × 100 = 7989.999… rounding down to 79.89.
        let lowerStored = ((lower * 100) - 1e-6).rounded(.up) / 100
        let upperStored = ((upper * 100) + 1e-6).rounded(.down) / 100

        guard lowerStored <= upperStored else { return nil }
        return lowerStored...upperStored
    }

    static func isValid(
        _ targetWeightKg: Double?,
        goal: GoalType?,
        currentWeightKg: Double?,
        heightCm: Double?
    ) -> Bool {
        guard let targetWeightKg else { return true }
        guard let range = allowedRange(goal: goal, currentWeightKg: currentWeightKg, heightCm: heightCm) else {
            return false
        }
        return range.contains(targetWeightKg)
    }
}
