import SwiftUI

/// What the estimate was read as, and what it assumed.
///
/// No confidence figure, by rule: `design.md` rule 1 asks for specific
/// uncertainty copy — "2 tbsp of ghee in the karahi" — in place of a percentage
/// nothing has calibrated and a reader would take for an accuracy rate.
struct MealAnalysisCard: View {
    let explanation: String
    let assumptions: [String]

    private var showsExplanation: Bool { !explanation.isEmpty }
    private var showsAssumptions: Bool { !assumptions.isEmpty }

    var body: some View {
        CircaCard {
            VStack(alignment: .leading, spacing: 14) {
                if showsExplanation {
                    VStack(alignment: .leading, spacing: 6) {
                        CircaSectionLabel("How this was estimated")

                        Text(explanation)
                            .font(.circaBody)
                            .foregroundStyle(Color.circaInk2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if showsExplanation, showsAssumptions {
                    CircaHairline(weight: .inCard)
                }

                if showsAssumptions {
                    VStack(alignment: .leading, spacing: 9) {
                        CircaSectionLabel("What Circa assumed")

                        VStack(alignment: .leading, spacing: 7) {
                            ForEach(Array(assumptions.enumerated()), id: \.offset) { index, assumption in
                                assumptionRow(number: index + 1, text: assumption)
                            }
                        }
                    }
                }
            }
        }
    }

    private func assumptionRow(number: Int, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text(number.formatted(.number.precision(.integerLength(2))))
                .font(.circaMono)
                .monospacedDigit()
                .foregroundStyle(Color.circaInk3)

            Text(text)
                .font(.circaBody)
                .foregroundStyle(Color.circaInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Assumption \(number). \(text)")
    }
}

/// The way into `NutritionSourcesView`. A row on the paper rather than a button
/// inside the card above, so a meal whose explanation a manual total superseded
/// still has one.
///
/// It owns its top rule: the `Entry` artboard draws the line as the row's border,
/// with the 44 pt target directly beneath it.
struct MealSourcesRow: View {
    @State private var showNutritionSources = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CircaHairline()
            sourcesButton
        }
    }

    private var sourcesButton: some View {
        Button {
            showNutritionSources = true
        } label: {
            HStack(spacing: 10) {
                Text("AI estimate · how this works & sources")
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 4)

                Image(systemName: "chevron.forward")
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaInk3)
            }
            .frame(minHeight: Circa.minHitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showNutritionSources) {
            NutritionSourcesView()
        }
    }
}
