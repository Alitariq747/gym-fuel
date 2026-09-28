import SwiftUI

struct DetailMacroSummaryCard: View {
    let macros: Macros
    let certainty: CircaCertainty
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var calorieSize = Circa.Display.entryTotal

    private struct Part: Identifiable {
        let glyph: CircaMacroGlyph.Macro
        let name: String
        let grams: Double
        var id: String { name }
    }

    private var parts: [Part] {
        [
            Part(glyph: .protein, name: "Protein", grams: macros.protein),
            Part(glyph: .carbs, name: "Carbs", grams: macros.carbs),
            Part(glyph: .fat, name: "Fat", grams: macros.fat)
        ]
    }

    var body: some View {
        let isStacked = dynamicTypeSize.isAccessibilitySize
        let totalLayout = isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(spacing: 12))

        CircaCard {
            VStack(alignment: .leading, spacing: 16) {
                totalLayout {
                    CircaMacroGlyph(.calories, size: .large)
                    calorieTotal
                }

                CircaHairline(weight: .inCard)

                if isStacked {
                    stackedParts
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(parts) { part in
                                partView(part)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        stackedParts
                    }
                }
            }
        }
    }

    private var stackedParts: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(parts) { partView($0, stacked: true) }
        }
    }

    private var calorieTotal: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                calorieValue
                Text("kcal").font(.circaMono).foregroundStyle(Color.circaInk3)
            }
            .fixedSize()
            VStack(alignment: .leading, spacing: 4) {
                calorieValue
                Text("kcal").font(.circaMono).foregroundStyle(Color.circaInk3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(MealCopy.calories(macros) ?? "") kilocalories\(certainty == .estimated ? ", estimated" : "")")
    }

    private var calorieValue: some View {
        CircaEstimate(MealCopy.calories(macros), certainty: certainty,
                      font: .system(size: calorieSize, weight: .semibold, design: .monospaced))
    }

    private func partView(_ part: Part, stacked: Bool = false) -> some View {
        let number = MealCopy.grams(part.grams)
        let layout = stacked
            ? AnyLayout(HStackLayout(spacing: 12))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
        return layout {
            CircaMacroGlyph(part.glyph)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    CircaEstimate(number, certainty: certainty, font: .circaMonoLarge)
                    Text("g").font(.circaMono).foregroundStyle(Color.circaInk3)
                }
                Text(part.name)
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaInk2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(part.name), \(number) grams\(certainty == .estimated ? ", estimated" : "")")
    }
}
