//
//  TargetsCopy.swift
//  GymFuel
//

import Foundation

/// The sentences that belong to the saved targets rather than to any one screen.
/// The targets screen (4d) and the plan screen (4f) both say them, so they are
/// written once. Pure: no UI, no Firebase.
///
/// The maintenance sentence is split around its number on purpose. `design.md`
/// rule 1 puts the dotted certainty rule under the **number**, not under prose,
/// so a screen renders three pieces and only the middle one carries the rule.
enum TargetsCopy {

    /// "Set at 83 kg on 19 Sep" — the day and the weight the current numbers were
    /// set at. Nil when either is missing, which is an account from before 4c.
    static func setAt(weightKg: Double?, on dayKey: String?, unit: BodyWeightUnit) -> String? {
        guard let weightKg, let dayKey, let date = DateKey.date(from: dayKey) else { return nil }

        let value = unit == .kilograms ? weightKg : BodyWeight.pounds(fromKilograms: weightKg)
        let weight = value.formatted(.number.precision(.fractionLength(0)))
        let day = date.formatted(.dateTime.day().month(.abbreviated))
        return "Set at \(weight) \(unit.shortLabel) on \(day)"
    }

    /// What the maintenance estimate is, said as a label rather than a claim.
    /// Never "burn", and nothing the user sees calls it one — `build-order.md`,
    /// *The rules*.
    static let maintenanceLabel = "To stay at your weight"
    /// The word before the number, which is hedged because the number is.
    static let maintenancePrefix = "about"
    /// The words after it.
    static let maintenanceSuffix = "kcal a day"
    /// What that estimate is worth, in one line, under the number.
    static let startingEstimate = "This is a starting estimate. Your weigh-ins will show whether it's right."

    /// The estimate itself. `MacroTargetCalculator` has already rounded it to 10;
    /// this only drops the decimals and groups the thousands.
    static func maintenanceValue(_ kcal: Double) -> String {
        kcal.formatted(.number.precision(.fractionLength(0)))
    }
}
