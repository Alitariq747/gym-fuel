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
    @State private var draft: MealAmountsDraft
    @FocusState private var focused: String?
    @ScaledMetric(relativeTo: .title3) private var fieldWidth: CGFloat = 92

    private let calculator = MealBreakdownCalculator()

    init(breakdown: MealBreakdown, onSave: @escaping (MealBreakdown) -> Void) {
        self.breakdown = breakdown
        self.onSave = onSave
        _draft = State(initialValue: MealAmountsDraft(breakdown))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header

            AdaptiveScrollContainer {
                VStack(alignment: .leading, spacing: 14) {
                    Text(MealCopy.amountsPromise)
                        .font(.circaBody)
                        .foregroundStyle(Color.circaInk2)
                        .fixedSize(horizontal: false, vertical: true)

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
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.top, 4)
                .padding(.bottom, 18)
            }
            .contentShape(Rectangle())
            .onTapGesture { focused = nil }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { totalBar }
        .circaPaper()
    }

    private var header: some View {
        HStack {
            Text("Edit amounts")
                .font(.headline)
                .foregroundStyle(Color.circaInk)
            Spacer(minLength: Circa.Space.rowGap)
            Button("Cancel") { dismiss() }
                .buttonStyle(.circa(.quiet))
        }
        .padding(.leading, Circa.Space.screenMargin)
        .padding(.trailing, 10)
        .padding(.top, 8)
    }

    private var totalBar: some View {
        MealAmountsTotalBar(
            before: displayedCalories(of: breakdown),
            after: draft.corrected.map(displayedCalories),
            certainty: calculator.provenance(of: draft.preview) == .estimated ? .estimated : .known,
            changedCount: draft.changedCount,
            canSave: draft.canSave,
            isTyping: focused != nil,
            onHideKeyboard: { focused = nil },
            onSave: save
        )
    }

    private func displayedCalories(of meal: MealBreakdown) -> Int {
        Int(calculator.total(of: meal).calories.rounded())
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
        Binding(get: { draft.text[id] ?? "" }, set: { draft.setText($0, for: id) })
    }

    private func save() {
        guard let corrected = draft.corrected else { return }

        onSave(corrected)
        dismiss()
    }
}
