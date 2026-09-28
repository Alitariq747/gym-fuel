//
//  MealBreakdownCard.swift
//  GymFuel
//
//  Created by Ahmad on 21/09/2026.
//

import SwiftUI

/// What the meal was made of, and what each part contributed. Rows and total
/// both come from `MealBreakdownCalculator`, never a stored literal, so what is
/// listed and what is totalled cannot drift — §4.
struct MealBreakdownCard: View {
    let breakdown: MealBreakdown
    var onEditAmounts: (() -> Void)? = nil

    private let calculator = MealBreakdownCalculator()

    var body: some View {
        CircaCard {
            VStack(alignment: .leading, spacing: Circa.Space.rowGap) {
                HStack {
                    CircaSectionLabel("Breakdown")
                    Spacer(minLength: 8)
                    if let onEditAmounts {
                        Button(action: onEditAmounts) {
                            Image(systemName: "pencil")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color.circaAccent)
                                .frame(minWidth: Circa.minHitTarget, minHeight: Circa.minHitTarget)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, -12)
                        .padding(.trailing, -12)
                        .accessibilityLabel("Edit amounts")
                    }
                }

                ForEach(Array(breakdown.items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        CircaHairline(weight: .inCard)
                    }

                    MealBreakdownRow(
                        title: item.name,
                        amount: MealCopy.amount(item.amount),
                        calories: MealCopy.calories(calculator.contribution(of: item)),
                        macros: calculator.contribution(of: item),
                        source: item.resolvedSource,
                        isAdjusted: item.amount?.isAdjusted ?? false,
                        sourceNote: item.sourceNote,
                        assumption: item.assumption
                    )

                    ForEach(item.components) { component in
                        MealBreakdownRow(
                            title: component.name,
                            amount: MealCopy.amount(component.amount),
                            calories: MealCopy.calories(calculator.contribution(of: component)),
                            macros: calculator.contribution(of: component),
                            source: component.resolvedSource,
                            isAdjusted: component.amount?.isAdjusted ?? false,
                            sourceNote: component.sourceNote,
                            assumption: component.assumption,
                            isComponent: true
                        )
                    }
                }

                CircaHairline(weight: .inCard)

                MealBreakdownRow(
                    title: "Meal total",
                    amount: nil,
                    calories: MealCopy.calories(calculator.total(of: breakdown)),
                    source: calculator.provenance(of: breakdown),
                    isAdjusted: false,
                    sourceNote: nil,
                    assumption: nil
                )
            }
        }
    }
}

/// One line of the breakdown. Takes plain values for the same reason
/// `CircaEntryRow` does: three types share one row, and Step 6's schema change
/// must not reach in here.
private struct MealBreakdownRow: View {
    let title: String
    let amount: String?
    /// `nil` is a descriptive part — shown, with no number and no rule.
    let calories: String?
    var macros: Macros? = nil
    let source: MealProvenance
    let isAdjusted: Bool
    let sourceNote: String?
    /// What was assumed about *this* part. It sits here rather than in a list of
    /// its own so the sentence and the amount it is about are the same tap.
    let assumption: String?
    var isComponent = false

    @Environment(\.dynamicTypeSize) private var typeSize

    /// design.md rule 8 — the number drops below the name rather than being
    /// squeezed beside wrapping text.
    private var isVertical: Bool { typeSize.isAccessibilitySize }

    /// An adjusted estimate keeps its dotted rule: correcting an amount removes
    /// one source of uncertainty and leaves the rest. `meal-contract.md` §5.
    private var certainty: CircaCertainty {
        source == .estimated ? .estimated : .known
    }

    private var provenance: String? {
        MealCopy.provenance(source: source, isAdjusted: isAdjusted, sourceNote: sourceNote)
    }

    private var assumptionLine: String? { MealCopy.assumption(assumption) }

    var body: some View {
        Group {
            if isVertical {
                VStack(alignment: .leading, spacing: 4) {
                    names
                    if let calories {
                        CircaEstimate(calories, certainty: certainty)
                    }
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    names
                    Spacer(minLength: 8)
                    if let calories {
                        CircaEstimate(calories, certainty: certainty)
                            .layoutPriority(1)
                    }
                }
            }
        }
        .padding(.leading, isComponent && !isVertical ? Circa.Space.rowGap : 0)
        .accessibilityElement(children: .combine)
    }

    private var names: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(isComponent ? .circaBody : .circaRow)
                .foregroundStyle(isComponent ? Color.circaInk2 : Color.circaInk)
                .fixedSize(horizontal: false, vertical: true)

            if amount != nil || macros != nil {
                MealMacroLine(amount: amount, macros: macros)
            }

            if let provenance {
                Text(provenance)
                    .font(.circaMono)
                    .foregroundStyle(Color.circaAccent)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let assumptionLine {
                Text(assumptionLine)
                    .font(.circaMono)
                    .foregroundStyle(Color.circaAccent)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// The amount, then what the part contributes. design.md rule 8: the macros drop
/// beneath the amount, then stack, rather than truncate.
private struct MealMacroLine: View {
    let amount: String?
    let macros: Macros?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                if let amount {
                    Text(amount)
                    if macros != nil { Text(verbatim: "·") }
                }
                grams(stacked: false)
            }
            VStack(alignment: .leading, spacing: 2) {
                if let amount { Text(amount) }
                grams(stacked: false)
            }
            VStack(alignment: .leading, spacing: 2) {
                if let amount { Text(amount) }
                grams(stacked: true)
            }
        }
        .font(.circaMono)
        .foregroundStyle(Color.circaInk3)
    }

    @ViewBuilder
    private func grams(stacked: Bool) -> some View {
        if let macros {
            let layout = stacked
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
                : AnyLayout(HStackLayout(spacing: 8))
            layout {
                gram(.protein, "Protein", macros.protein)
                gram(.carbs, "Carbs", macros.carbs)
                gram(.fat, "Fat", macros.fat)
            }
        }
    }

    private func gram(_ glyph: CircaMacroGlyph.Macro, _ name: String, _ value: Double) -> some View {
        let number = MealCopy.grams(value)
        return HStack(spacing: 3) {
            CircaInlineGlyph(glyph)
            Text(number).monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(number) grams")
    }
}
