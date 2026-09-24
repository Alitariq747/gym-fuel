import SwiftUI

struct DetailMacroSummaryCard: View {
    let macros: Macros
    let certainty: CircaCertainty
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var calorieSize = Circa.Display.entryTotal

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                stackedSummary
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .bottom, spacing: 18) {
                        calorieTotal.fixedSize()
                        Spacer(minLength: 0)
                        HStack(spacing: 18) {
                            macro("PROT", name: "Protein", value: macros.protein)
                            macro("CARB", name: "Carbohydrate", value: macros.carbs)
                            macro("FAT", name: "Fat", value: macros.fat)
                        }
                        .fixedSize()
                    }
                    stackedSummary
                }
            }
        }
        .foregroundStyle(Color.circaInk)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stackedSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            calorieTotal
            macro("Protein", name: "Protein", value: macros.protein, stacked: true)
            macro("Carbs", name: "Carbohydrate", value: macros.carbs, stacked: true)
            macro("Fat", name: "Fat", value: macros.fat, stacked: true)
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

    private func macro(_ label: String, name: String, value: Double, stacked: Bool = false) -> some View {
        let number = value.rounded().formatted(.number.precision(.fractionLength(0)))
        let layout = stacked
            ? AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 10))
            : AnyLayout(VStackLayout(alignment: .trailing, spacing: 2))
        return layout {
            CircaEstimate(number, certainty: certainty)
            Text(label)
                .font(.circaMono)
                .foregroundStyle(Color.circaInk3)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(number) grams\(certainty == .estimated ? ", estimated" : "")")
    }
}
