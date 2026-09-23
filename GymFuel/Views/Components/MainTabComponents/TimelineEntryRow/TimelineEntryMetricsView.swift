import SwiftUI

struct TimelineEntryMetricsView: View {
    let entry: LogEntry
    let state: TimelineEntryRowState
    let showRevealedCalories: Bool
    let showRevealedProtein: Bool
    let showRevealedCarbs: Bool
    let showRevealedFat: Bool

    var body: some View {
        if let macros = state.feedback?.macros,
           showRevealedCalories || showRevealedProtein || showRevealedCarbs || showRevealedFat {
            foodMetricRows(macros)
        }
    }

    @ViewBuilder
    private func foodMetricRows(_ macros: Macros) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            if showRevealedCalories {
                primaryMetricStat(symbol: "flame.fill", value: "\(Int(macros.calories.rounded())) Calories", color: .primary)
            }

            HStack(spacing: 7) {
                if showRevealedProtein {
                    secondaryMetricStat(symbol: "fish", value: "\(Int(macros.protein.rounded()))g", color: .circaInk2)
                }
                if showRevealedCarbs {
                    secondaryMetricStat(symbol: "leaf.fill", value: "\(Int(macros.carbs.rounded()))g", color: .circaInk2)
                }
                if showRevealedFat {
                    secondaryMetricStat(symbol: "drop.fill", value: "\(Int(macros.fat.rounded()))g", color: .pink)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
        }
        .padding(.top, 1)
    }

    @ViewBuilder
    private func primaryMetricStat(symbol: String, value: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Image(systemName: symbol)
                .font(.caption.weight(.regular))
                .foregroundStyle(color)
            Text(value)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.circaInk)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func secondaryMetricStat(symbol: String, value: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.caption2.weight(.regular))
                .foregroundStyle(color.opacity(0.72))
                .frame(width: 14, height: 14)
            Text(value)
                .font(.caption2.weight(.regular))
                .foregroundStyle(Color.circaInk2)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }
}
