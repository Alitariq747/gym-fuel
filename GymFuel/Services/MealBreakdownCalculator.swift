//
//  MealBreakdownCalculator.swift
//  GymFuel
//
//  Created by Ahmad on 21/09/2026.
//

import Foundation

/// Works out what a meal's parts add up to, following `meal-contract.md` §4 and
/// §5. Pure: no Firebase, no UI, no rounding except where a number is handed to
/// a screen.
struct MealBreakdownCalculator {

    // MARK: - Contribution

    /// What this part adds to its item. `nil` means descriptive — shown without a
    /// number, contributing nothing.
    func contribution(of component: MealComponent) -> Macros? {
        guard let nutrition = component.nutrition else { return nil }
        return nutrition.scaled(by: component.amount?.scale ?? 1)
    }

    /// What this item adds to the meal.
    ///
    /// An item contributes its own nutrition when it has one, and otherwise the
    /// sum of its components'. The two are mutually exclusive, which is what makes
    /// counting an ingredient twice unreachable rather than merely unlikely.
    ///
    /// **A component-priced item's own amount does not scale its components.**
    /// Whichever level carries the nutrition is the level that carries the handle:
    /// one bowl of stew is described by its oil and chicken, so scaling both
    /// the item and its parts would apply the same correction twice.
    func contribution(of item: MealItem) -> Macros? {
        if let nutrition = item.nutrition {
            return nutrition.scaled(by: item.amount?.scale ?? 1)
        }

        let parts = item.components.compactMap { contribution(of: $0) }
        guard !parts.isEmpty else { return nil }

        return parts.reduce(.zero, +)
    }

    /// The meal total, at full precision. Round once, at the point of display.
    func total(of breakdown: MealBreakdown) -> Macros {
        breakdown.items
            .compactMap { contribution(of: $0) }
            .reduce(.zero, +)
    }

    // MARK: - Editing

    /// The calorie difference an edit makes, as the screen will show it.
    ///
    /// The difference of the two *displayed* totals, not the rounded difference of
    /// the exact ones, so `477 → 384 · −93` always adds up on screen.
    func displayedCalorieDelta(from before: MealBreakdown, to after: MealBreakdown) -> Int {
        Int(total(of: after).calories.rounded()) - Int(total(of: before).calories.rounded())
    }

    // MARK: - Assumptions

    /// Every assumption this meal rests on, **most consequential first**, so
    /// `.first` is the one worth a single line on the timeline.
    ///
    /// The breakdown is the only source. An assumption with no node to sit on has
    /// nothing the user can correct, so a meal with no breakdown — one the model
    /// could price no part of, or one whose total the user typed — says nothing
    /// rather than reaching for a sentence that fits every meal equally.
    func assumptions(of feedback: LogEntryFeedback?) -> [String] {
        guard let feedback else { return [] }

        var seen = Set<String>()
        return ranked(feedback)
            .compactMap { MealCopy.assumption($0) }
            .filter { seen.insert($0).inserted }
    }

    private struct RankedAssumption {
        let calories: Double
        let order: Int
        let text: String
    }

    /// Breakdown assumptions, largest contribution first. Ties keep the order the
    /// meal was written in, so the timeline's line does not reshuffle between reads.
    private func ranked(_ feedback: LogEntryFeedback) -> [String] {
        guard let breakdown = feedback.breakdown, breakdown.isSupported else { return [] }

        var found: [RankedAssumption] = []

        func add(_ text: String?, _ calories: Macros?) {
            guard let text else { return }
            found.append(RankedAssumption(
                calories: calories?.calories ?? 0,
                order: found.count,
                text: text
            ))
        }

        for item in breakdown.items {
            add(item.assumption, contribution(of: item))
            for component in item.components {
                add(component.assumption, contribution(of: component))
            }
        }

        return found
            .sorted { $0.calories != $1.calories ? $0.calories > $1.calories : $0.order < $1.order }
            .map(\.text)
    }

    // MARK: - Superseding (§6)

    /// What the feedback becomes when the user types a meal total.
    ///
    /// A typed total asserts a number the breakdown does not produce, and the two
    /// cannot both be current — so everything the old numbers explained goes with
    /// them. Supersede means delete, not grey out: if a superseded breakdown
    /// survived, the card, the timeline's assumption line, the saved-meal snapshot
    /// would each have to re-implement "is this superseded?", and one
    /// of them would get it wrong.
    ///
    /// Built fresh rather than mutated, so a field added later cannot quietly
    /// survive an override by being forgotten here.
    static func superseding(
        _: LogEntryFeedback?,
        withUserTotal macros: Macros
    ) -> LogEntryFeedback {
        LogEntryFeedback(
            explanation: "",
            confidence: nil,
            macros: macros,
            breakdown: nil,
            macrosProvenance: .userTotal
        )
    }

    /// The saved-meal form of the same rule. Mutates rather than rebuilds, because
    /// a saved meal's other fields are identity — id, name, when it was made — not
    /// analysis, so there is nothing there that an override should discard.
    static func superseding(_ meal: SavedMeal, withUserTotal macros: Macros) -> SavedMeal {
        var updated = meal
        updated.macros = macros
        updated.breakdown = nil
        updated.macrosProvenance = .userTotal
        return updated
    }

    // MARK: - Provenance

    /// A total is reference-backed only if every number in it is. Mixed stays an
    /// estimate: uncertainty propagates upward, and never averages away.
    func provenance(of breakdown: MealBreakdown) -> MealProvenance {
        let sources = breakdown.items.flatMap { contributingSources(of: $0) }
        guard !sources.isEmpty else { return .estimated }

        return sources.allSatisfy { $0 == .reference } ? .reference : .estimated
    }

    /// The nodes that actually carry a number. A descriptive component has no say
    /// in how certain the total is.
    private func contributingSources(of item: MealItem) -> [MealProvenance] {
        guard item.nutrition == nil else { return [item.resolvedSource] }

        return item.components
            .filter { $0.nutrition != nil }
            .map(\.resolvedSource)
    }
}
