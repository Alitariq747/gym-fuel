import SwiftUI

struct DetailMacroSummaryCard: View {
    let macros: Macros
    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.secondarySystemGroupedBackground)
    }

    private var cardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.fuelOrange)

                Text("\(Int(macros.calories.rounded()))")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())

                Text("total calories")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                macroColumn(title: "Protein", value: macros.protein, symbol: "fish", color: .fuelBlue)
                macroColumn(title: "Carbs", value: macros.carbs, symbol: "leaf.fill", color: .fuelGreen)
                macroColumn(title: "Fat", value: macros.fat, symbol: "drop.fill", color: .pink)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(cardStroke, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.14 : 0.065), radius: 14, y: 7)
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
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
