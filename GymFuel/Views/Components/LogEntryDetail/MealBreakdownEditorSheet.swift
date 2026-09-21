//
//  MealBreakdownEditorSheet.swift
//  GymFuel
//
//  Created by Ahmad on 21/09/2026.
//

import SwiftUI

/// Correcting the amounts in one meal.
///
/// Every edit writes `adjustedQuantity` and nothing else, so the first estimate
/// survives and several corrections apply together on one Save. No AI call: the
/// stored nutrition is scaled. `meal-contract.md` §6.
///
/// Like `TargetsEditorSheet`, it knows nothing about Firebase — it is handed a
/// breakdown and hands one back.
struct MealBreakdownEditorSheet: View {
    let breakdown: MealBreakdown
    let onSave: (MealBreakdown) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var typed: [String: String]
    @FocusState private var focused: String?
    @ScaledMetric(relativeTo: .title3) private var fieldWidth: CGFloat = 92

    private let calculator = MealBreakdownCalculator()

    init(breakdown: MealBreakdown, onSave: @escaping (MealBreakdown) -> Void) {
        self.breakdown = breakdown
        self.onSave = onSave
        _typed = State(initialValue: Self.startingText(for: breakdown))
    }

    // MARK: - What Save will write

    /// The corrected breakdown, or `nil` while any field is empty, not a number
    /// or negative — which is what disables Save.
    private var draft: MealBreakdown? {
        var copy = breakdown

        for item in copy.items.indices {
            guard corrected(&copy.items[item].amount, id: copy.items[item].id) else { return nil }

            for part in copy.items[item].components.indices {
                let component = copy.items[item].components[part]
                guard corrected(&copy.items[item].components[part].amount, id: component.id) else { return nil }
            }
        }

        return copy
    }

    /// Typing the original number back clears the correction rather than storing
    /// one that changes nothing.
    private func corrected(_ amount: inout MealAmount?, id: String) -> Bool {
        guard let text = typed[id] else { return true }
        guard let value = MealCopy.quantity(from: text), value >= 0 else { return false }

        // Read before writing: `amount` is `inout`, so comparing against it in
        // the same expression that assigns to it is an overlapping access.
        let estimated = amount?.quantity
        amount?.adjustedQuantity = value == estimated ? nil : value
        return true
    }

    private var canSave: Bool {
        guard let draft else { return false }
        return draft != breakdown
    }

    private var deltaLine: String? {
        guard let draft else { return nil }

        return MealCopy.delta(
            from: Int(calculator.total(of: breakdown).calories.rounded()),
            to: Int(calculator.total(of: draft).calories.rounded())
        )
    }

    // MARK: - Body

    var body: some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 14) {
                header

                CircaCard {
                    VStack(alignment: .leading, spacing: Circa.Space.rowGap) {
                        ForEach(Array(breakdown.items.enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                CircaHairline(weight: .inCard)
                            }
                            rows(for: item)
                        }
                    }
                }

                Text(deltaLine ?? "Enter an amount for every line.")
                    .font(.circaMono)
                    .foregroundStyle(deltaLine == nil ? Color.circaDanger : Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Button(action: save) {
                    Text("Save").frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary, height: 52))
                .disabled(!canSave)
            }
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.vertical, 18)
        }
        .circaPaper()
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Edit amounts")
                .font(.circaTitle)
                .foregroundStyle(Color.circaInk)
            Spacer(minLength: Circa.Space.rowGap)
            Button("Cancel") { dismiss() }
                .buttonStyle(.circa(.quiet))
        }
    }

    @ViewBuilder
    private func rows(for item: MealItem) -> some View {
        row(id: item.id, name: item.name, amount: item.amount, editable: item.isAmountEditable)

        ForEach(item.components) { component in
            row(
                id: component.id,
                name: component.name,
                amount: component.amount,
                editable: component.isAmountEditable,
                isComponent: true
            )
        }
    }

    /// The name above the field rather than beside it, so nothing truncates at
    /// accessibility sizes — design.md rule 8, solved by layout not by a branch.
    @ViewBuilder
    private func row(
        id: String,
        name: String,
        amount: MealAmount?,
        editable: Bool,
        isComponent: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(isComponent ? .circaBody : .circaRow)
                .foregroundStyle(isComponent ? Color.circaInk2 : Color.circaInk)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if editable, let amount {
                    TextField("0", text: binding(for: id))
                        .font(.circaMonoLarge)
                        .monospacedDigit()
                        .foregroundStyle(Color.circaInk)
                        .keyboardType(.decimalPad)
                        .focused($focused, equals: id)
                        .frame(width: fieldWidth)
                    Text(amount.unit)
                        .font(.circaMono)
                        .foregroundStyle(Color.circaInk3)
                } else {
                    // A composite's own amount, or a descriptive part: shown so
                    // the meal still reads whole, never edited. §4.
                    Text(MealCopy.amount(amount) ?? "No amount to change")
                        .font(.circaMono)
                        .foregroundStyle(Color.circaInk3)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.leading, isComponent ? Circa.Space.rowGap : 0)
        .frame(minHeight: Circa.minHitTarget, alignment: .leading)
    }

    private func binding(for id: String) -> Binding<String> {
        Binding(get: { typed[id] ?? "" }, set: { typed[id] = $0 })
    }

    private func save() {
        guard let draft else { return }

        onSave(draft)
        dismiss()
    }

    private static func startingText(for breakdown: MealBreakdown) -> [String: String] {
        var text: [String: String] = [:]

        for item in breakdown.items {
            if item.isAmountEditable, let amount = item.amount {
                text[item.id] = MealCopy.editableQuantity(amount.effectiveQuantity)
            }
            for component in item.components where component.isAmountEditable {
                if let amount = component.amount {
                    text[component.id] = MealCopy.editableQuantity(amount.effectiveQuantity)
                }
            }
        }

        return text
    }
}
