import SwiftUI

struct DetailMacroSummaryCard: View {
    let macros: Macros
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var cardBackground: Color {
        Color.circaCard
    }

    private var cardStroke: Color {
        Color.circaCardBorder
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.circaAccent)

                Text("\(Int(macros.calories.rounded()))")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())

                Text("total calories")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color.circaInk2)
            }
            .frame(maxWidth: .infinity)

            Group {
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(spacing: 12))
                    : AnyLayout(HStackLayout(spacing: 12))
                layout {
                    macroColumn(title: "Protein", value: macros.protein, symbol: "fish", color: .circaInk2)
                    macroColumn(title: "Carbs", value: macros.carbs, symbol: "leaf.fill", color: .circaInk2)
                    macroColumn(title: "Fat", value: macros.fat, symbol: "drop.fill", color: .circaInk2)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(cardStroke, lineWidth: 1)
        }
    }

    private func macroColumn(title: String, value: Double, symbol: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(Int(value.rounded())) g")
                .font(.headline.weight(.bold))
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color.circaInk2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
