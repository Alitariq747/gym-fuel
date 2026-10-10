//
//  MealAmountsDraft.swift
//  GymFuel
//

import Foundation

/// The amounts being corrected in one meal, before Save. Pure, so the editor's
/// rules are tested rather than tapped. `meal-contract.md` §6.
struct MealAmountsDraft {

    /// The meal as the editor opened it. The delta is measured from here.
    let opened: MealBreakdown

    /// What each editable line's field holds, by node id.
    private(set) var text: [String: String]

    private let startingText: [String: String]

    init(_ breakdown: MealBreakdown) {
        opened = breakdown
        startingText = Dictionary(
            Self.editableAmounts(in: breakdown).map { ($0.id, MealCopy.editableQuantity($0.amount.effectiveQuantity)) },
            uniquingKeysWith: { first, _ in first }
        )
        text = startingText
    }

    // MARK: - Fields

    mutating func setText(_ value: String, for id: String) {
        guard text[id] != nil else { return }
        text[id] = value
    }

    func isValid(_ id: String) -> Bool {
        text[id].map { Self.value(of: $0) != nil } ?? true
    }

    /// Every field that reads as an amount, applied. One that doesn't keeps the
    /// amount the editor opened with.
    var preview: MealBreakdown {
        var copy = opened
        for item in copy.items.indices {
            applyText(to: &copy.items[item].amount, id: copy.items[item].id)
            for part in copy.items[item].components.indices {
                applyText(to: &copy.items[item].components[part].amount, id: copy.items[item].components[part].id)
            }
        }
        return copy
    }

    /// What Save writes, or `nil` while any field is empty, not a number or negative.
    var corrected: MealBreakdown? {
        text.keys.allSatisfy(isValid) ? preview : nil
    }

    var canSave: Bool {
        corrected.map { $0 != opened } ?? false
    }

    var changedCount: Int {
        zip(Self.editableAmounts(in: opened), Self.editableAmounts(in: preview))
            .filter { $0.amount != $1.amount }
            .count
    }

    /// A field still showing what it opened with leaves its line untouched, and
    /// one showing the estimate clears the correction. Both compare as the field
    /// shows them, so an estimate past two decimals is never "corrected" to itself.
    private func applyText(to amount: inout MealAmount?, id: String) {
        guard let typed = text[id], typed != startingText[id],
              let value = Self.value(of: typed),
              let estimate = amount?.quantity
        else { return }

        let isEstimate = MealCopy.editableQuantity(value) == MealCopy.editableQuantity(estimate)
        amount?.adjustedQuantity = isEstimate ? nil : value
    }

    // MARK: - Reading the tree

    private static func value(of text: String) -> Double? {
        guard let value = MealCopy.quantity(from: text), value >= 0 else { return nil }
        return value
    }

    /// Every line that can be corrected, in the meal's order. §4 decides which:
    /// a dish priced by its parts has no handle of its own.
    private static func editableAmounts(in breakdown: MealBreakdown) -> [(id: String, amount: MealAmount)] {
        breakdown.items.flatMap { item -> [(id: String, amount: MealAmount)] in
            var lines: [(id: String, amount: MealAmount)] = []
            if item.isAmountEditable, let amount = item.amount {
                lines.append((item.id, amount))
            }
            for component in item.components where component.isAmountEditable {
                if let amount = component.amount {
                    lines.append((component.id, amount))
                }
            }
            return lines
        }
    }
}
