//
//  MealCopy.swift
//  GymFuel
//

import Foundation

/// The words a meal's breakdown is made of. The card, and later the editor, both
/// say them, so they are written once. Pure: no UI, no Firebase.
enum MealCopy {

    /// "2 tbsp", "0.5 katori" — the amount as it stands now, so a corrected row
    /// reads as what the user said rather than what was first guessed. Trailing
    /// zeros go and fractions stop at two places: a household measure is not
    /// precise enough to justify a third.
    static func amount(_ amount: MealAmount?) -> String? {
        guard let amount else { return nil }

        let value = amount.effectiveQuantity
            .formatted(.number.precision(.fractionLength(0...2)))
        let unit = amount.unit.trimmingCharacters(in: .whitespaces)

        return unit.isEmpty ? value : "\(value) \(unit)"
    }

    /// The amount as a text field should show it. No grouping separator, so what
    /// is shown always parses back — "1000", never "1,000".
    static func editableQuantity(_ value: Double) -> String {
        value.formatted(.number.grouping(.never).precision(.fractionLength(0...2)))
    }

    /// What the user typed, as a number. A decimal pad offers the locale's
    /// separator, so a comma has to be accepted as readily as a dot.
    static func quantity(from text: String) -> Double? {
        let separator = Locale.current.decimalSeparator ?? "."
        return Double(text.replacingOccurrences(of: separator, with: "."))
    }

    /// "607" — a calorie figure for a row, rounded once at the point of display.
    static func calories(_ macros: Macros?) -> String? {
        guard let macros else { return nil }
        return macros.calories.rounded().formatted(.number.precision(.fractionLength(0)))
    }

    /// "607 → 514 kcal · −93" — what an edit will do, before it is committed.
    ///
    /// Both ends are the *displayed* totals, so the three numbers on the line
    /// always agree with each other and with the rows above. `meal-contract.md` §6.
    static func delta(from before: Int, to after: Int) -> String {
        let change = after - before
        guard change != 0 else { return "\(after) kcal · no change" }

        return "\(before) → \(after) kcal · \(change > 0 ? "+" : "−")\(abs(change))"
    }

    /// "2 assumptions · Full-fat, not light" — the timeline's single line, naming
    /// the assumption that moves the number most. One assumption stands alone, and
    /// a count with nothing to name is not worth a line at all.
    static func assumptionLine(count: Int, lead: String?) -> String? {
        guard let lead, !lead.isEmpty else { return nil }

        return count > 1 ? "\(count) assumptions · \(lead)" : lead
    }

    /// What a failed entry kept. design.md rule 6 — the card leads with what
    /// survived, which is what makes **Try again** cost the user nothing.
    enum Preserved {
        case words
        case photo
    }

    /// "You're offline. Reconnect and try again. Your words are saved — nothing
    /// to retype." The reason comes from the attempt; the clause is the rule.
    static func failure(reason: String?, preserved: Preserved) -> String {
        let trimmed = reason?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var lead = trimmed.isEmpty ? "We couldn't reach Circa." : trimmed

        if let last = lead.last, !".!?".contains(last) {
            lead += "."
        }

        switch preserved {
        case .words: return "\(lead) Your words are saved — nothing to retype."
        case .photo: return "\(lead) Your photo is saved — nothing to re-shoot."
        }
    }

    /// What to say about where a number came from, or `nil` when there is nothing
    /// worth saying.
    ///
    /// A plain estimate returns `nil` on purpose: the dotted rule under the number
    /// already carries that, and repeating "Estimated" on every row would make the
    /// rows that *do* differ harder to see, not easier. `meal-contract.md` §5.
    static func provenance(
        source: MealProvenance,
        isAdjusted: Bool,
        sourceNote: String? = nil
    ) -> String? {
        let note = sourceNote?.trimmingCharacters(in: .whitespaces)
        let reference = (note?.isEmpty == false ? note : nil) ?? "From a label"

        switch (source, isAdjusted) {
        case (.estimated, false): return nil
        case (.estimated, true): return "You set the amount"
        case (.reference, false): return reference
        case (.reference, true): return "\(reference), your amount"
        case (.userTotal, _): return "You set this total"
        }
    }
}
