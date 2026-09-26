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

    /// The estimate itself. `MacroTargetCalculator` has already rounded it to 10;
    /// this only drops the decimals and groups the thousands.
    static func maintenanceValue(_ kcal: Double) -> String {
        kcal.formatted(.number.precision(.fractionLength(0)))
    }

    // MARK: - Editing the four numbers

    static func fieldLabel(_ field: TargetField) -> String {
        switch field {
        case .calories: return "Calories"
        case .protein: return "Protein"
        case .carbs: return "Carbs"
        case .fat: return "Fat"
        }
    }

    static func fieldUnit(_ field: TargetField) -> String {
        field == .calories ? "kcal" : "g"
    }

    /// "You changed your carbs" · "You changed your protein and fat".
    ///
    /// Ordered by field rather than by the set it is given, so the same three
    /// edits always produce the same sentence.
    static func changedHeadline(_ fields: Set<TargetField>) -> String {
        let names = TargetField.allCases
            .filter(fields.contains)
            .map { fieldLabel($0).lowercased() }

        guard let last = names.last else { return "You changed your numbers" }
        guard names.count > 1 else { return "You changed your \(last)" }
        return "You changed your \(names.dropLast().joined(separator: ", ")) and \(last)"
    }

    static let reconcileQuestion = "Would you like to update your other nutrition goals to match?"
    static let reviewChanges = "Review these changes, then tap Save to apply them."

    /// "Protein 170 g → 157 g"
    static func changeLine(_ change: TargetChange) -> String {
        let unit = fieldUnit(change.field)
        return "\(fieldLabel(change.field)) \(whole(change.before)) \(unit) → \(whole(change.after)) \(unit)"
    }

    /// The same line for VoiceOver, where "→" reads as nothing useful — and which
    /// does not mirror wrongly in a right-to-left layout.
    static func changeLineSpoken(_ change: TargetChange) -> String {
        let unit = fieldUnit(change.field)
        return "\(fieldLabel(change.field)) \(whole(change.before)) \(unit) to \(whole(change.after)) \(unit)"
    }

    /// Why the calories that were just worked out are higher than the ones asked
    /// for. Which floor held is worth saying: "the lowest this app sets" and
    /// "your protein and fat" are different things to change.
    static func floorNote(resolved: Macros, requestedCalories: Double, gender: Gender) -> String? {
        guard resolved.calories > requestedCalories.rounded() else { return nil }

        let held = whole(resolved.calories)
        return resolved.calories <= SafetyLimits.calorieFloor(for: gender)
            ? "Saving as \(held) kcal — the lowest this app will set."
            : "Saving as \(held) kcal — less would not cover the protein and fat above."
    }

    static let savePickFirst = "Choose how to update your numbers before saving."
    static let saveNeedsValue = "Every number needs a value."

    private static func whole(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }
}
