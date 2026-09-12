//
//  BodyWeight.swift
//  GymFuel
//

import Foundation

/// The unit a body weight is entered and displayed in. Storage is always
/// kilograms; this only ever affects the keyboard-free pickers and the label.
///
/// Named `BodyWeightUnit` rather than `WeightUnit` on purpose:
/// `OnboardingWeightStepView` declares a file-private `WeightUnit`, and a
/// module-level type of the same name would be legally shadowed there but is a
/// trap for the next reader.
enum BodyWeightUnit: String, CaseIterable, Identifiable, Sendable {
    case kilograms
    case pounds

    /// Persisted so a lb user does not re-pick lbs at every weigh-in. A one-off
    /// profile edit resetting to kg was a shrug; a weigh-in is meant to be
    /// weekly or better, and that friction sits on the exact loop the trend
    /// depends on.
    static let preferenceKey = "lifteats.weighin.unit"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .kilograms: "kg"
        case .pounds: "lbs"
        }
    }
}

/// Conversion, rounding and digit decomposition for body weights.
///
/// Extracted as a value type — not as a shared view — so the arithmetic is
/// unit-testable and identical in every caller. The literal `0.45359237`
/// previously appeared at four sites in `EditWeightSheet` and four more in
/// `OnboardingWeightStepView`; the round-trip guarantees below only hold if
/// every caller uses the same code.
enum BodyWeight {
    /// The international avoirdupois pound, exactly.
    static let kilogramsPerPound: Double = 0.45359237

    /// The range the pickers offer, in kilograms. Clamping happens in kg only —
    /// deriving the lb bounds from these means a value near either end no longer
    /// shifts when the user switches units. (The old `30...200` kg and
    /// `66...440` lb ranges were not mirrors: 30 kg is 66.14 lb.)
    static let minimumKilograms: Double = 30
    static let maximumKilograms: Double = 200

    // MARK: - Conversion

    static func kilograms(fromPounds pounds: Double) -> Double {
        pounds * kilogramsPerPound
    }

    static func pounds(fromKilograms kilograms: Double) -> Double {
        kilograms / kilogramsPerPound
    }

    // MARK: - Rounding

    /// Rounds to two decimal places for persistence.
    ///
    /// **Two, not one, and the difference is load-bearing.** The lb picker moves
    /// in 0.2 lb steps. Two decimal places in kg introduces at most 0.005 kg
    /// ≈ 0.011 lb of error, and a multiple of 0.2 is never closer than 0.05 to a
    /// 1-dp rounding midpoint — so lb → kg → lb round-trips exactly. At one
    /// decimal place the error is 0.05 kg ≈ 0.11 lb, which exceeds 0.05 lb, and
    /// the round trip breaks.
    static func roundedForStorage(_ kilograms: Double) -> Double {
        (kilograms * 100).rounded() / 100
    }

    static func clampedToRange(_ kilograms: Double) -> Double {
        min(max(kilograms, minimumKilograms), maximumKilograms)
    }

    // MARK: - Picker decomposition

    /// Splits a value into whole units and tenths for the two-wheel pickers.
    ///
    /// Integer arithmetic throughout: `804 / 10` and `804 % 10`, never
    /// `floor(80.4)` and `(80.4 - 80) * 10`. Binary floating point makes the
    /// second form return 3 for the tenths often enough to matter.
    static func decompose(_ value: Double) -> (whole: Int, tenth: Int) {
        let tenths = Int((value * 10).rounded())
        return (tenths / 10, tenths % 10)
    }

    /// The inverse of `decompose`. `Double(804) / 10` is exactly 80.4;
    /// `80 + 4 / 10.0` is not reliably so.
    static func recompose(whole: Int, tenth: Int) -> Double {
        Double(whole * 10 + tenth) / 10
    }

    // MARK: - Display

    /// One decimal place, in the user's locale — `"80,4"` in German, not `"80.4"`.
    /// `String(format:)` would hard-code the decimal separator.
    static func displayString(kilograms: Double, unit: BodyWeightUnit) -> String {
        let value = unit == .kilograms ? kilograms : pounds(fromKilograms: kilograms)
        let formatted = value.formatted(.number.precision(.fractionLength(1)))
        return "\(formatted) \(unit.shortLabel)"
    }
}
