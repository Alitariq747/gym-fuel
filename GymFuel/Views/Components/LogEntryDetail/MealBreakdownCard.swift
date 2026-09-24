//
//  MealBreakdownCard.swift
//  GymFuel
//
//  Created by Ahmad on 21/09/2026.
//

import SwiftUI

/// What the meal was made of, and what each part contributed. Read-only until
/// 5e. Rows and total both come from `MealBreakdownCalculator`, never a stored
/// literal, so what is listed and what is totalled cannot drift — §4.
struct MealBreakdownCard: View {
    let breakdown: MealBreakdown

    private let calculator = MealBreakdownCalculator()

    var body: some View {
        CircaCard {
            VStack(alignment: .leading, spacing: Circa.Space.rowGap) {
                CircaSectionLabel("Breakdown")

                ForEach(Array(breakdown.items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        CircaHairline(weight: .inCard)
                    }

                    MealBreakdownRow(
                        title: item.name,
                        amount: MealCopy.amount(item.amount),
                        calories: MealCopy.calories(calculator.contribution(of: item)),
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

            if let amount {
                Text(amount)
                    .font(.circaMono)
                    .foregroundStyle(Color.circaInk3)
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
