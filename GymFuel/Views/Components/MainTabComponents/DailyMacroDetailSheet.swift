import SwiftUI

struct DailyMacroDetailSheet: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let targetMacros: Macros
    let consumedMacros: Macros

    private var remainingCalories: Int {
        Int((targetMacros.calories - consumedMacros.calories).rounded())
    }

    private var remainingLabel: String {
        remainingCalories < 0 ? "over" : "left"
    }

    private var progressAnimation: Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.55)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 18) {
                calorieMeta("Eaten", value: Int(consumedMacros.calories.rounded()))
                    .frame(maxWidth: .infinity, alignment: .leading)

                calorieProgressRing

                calorieMeta("Target", value: Int(targetMacros.calories.rounded()), alignment: .trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    summaryTile("PRO", symbol: "fish", current: consumedMacros.protein, target: targetMacros.protein)
                        .frame(minWidth: 90)
                    summaryTile("CARB", symbol: "leaf.fill", current: consumedMacros.carbs, target: targetMacros.carbs)
                        .frame(minWidth: 90)
                    summaryTile("FAT", symbol: "drop.fill", current: consumedMacros.fat, target: targetMacros.fat)
                        .frame(minWidth: 90)
                }

                VStack(spacing: 8) {
                    summaryTile("PRO", symbol: "fish", current: consumedMacros.protein, target: targetMacros.protein)
                    summaryTile("CARB", symbol: "leaf.fill", current: consumedMacros.carbs, target: targetMacros.carbs)
                    summaryTile("FAT", symbol: "drop.fill", current: consumedMacros.fat, target: targetMacros.fat)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(Color.circaCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.circaCardBorder, lineWidth: 1)
        }
    }

    private var calorieProgressRing: some View {
        let progress = min(max(consumedMacros.calories / max(targetMacros.calories, 1), 0), 1)
        let ringColor: Color = consumedMacros.calories > targetMacros.calories ? .circaAccentLarge : .circaInk

        return ZStack {
            Circle()
                .stroke(ringColor.opacity(0.10), lineWidth: 9)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(abs(remainingCalories))")
                    .font(.title3.weight(.bold))
                    .contentTransition(.numericText())
                    .animation(progressAnimation, value: remainingCalories)
                Text(remainingLabel)
                    .font(.caption2)
                    .foregroundStyle(Color.circaInk2)
                    .animation(.easeOut(duration: 0.2), value: remainingLabel)
            }
        }
        .frame(width: 108, height: 108)
        .animation(progressAnimation, value: progress)
    }

    private func summaryTile(_ short: String, symbol: String, current: Double, target: Double) -> some View {
        let progress = min(max(current / max(target, 1), 0), 1)
        let baseColor: Color = switch short {
        case "PRO": .circaInk
        case "CARB": .circaInk2
        default: .circaAccentLarge
        }
        let fillColor: Color = current > target ? .circaAccentLarge : baseColor

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(baseColor)
                    .frame(width: 14, height: 14)
                Text(short)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.circaInk2)
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(Int(current.rounded()))")
                    .font(.headline.weight(.bold))
                    .contentTransition(.numericText())
                    .animation(progressAnimation, value: current)
                Text("/ \(Int(target.rounded()))g")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.circaInk2)
            }
            Capsule()
                .fill(Color.circaBarTrack)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(fillColor)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(x: progress, y: 1, anchor: .leading)
                        .animation(progressAnimation, value: progress)
                }
                .frame(height: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.circaSunken, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.circaCardBorder, lineWidth: 1)
        }
    }

    private func calorieMeta(_ label: String, value: Int, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.circaInk2)
            Text("\(value)")
                .font(.headline.weight(.bold))
                .contentTransition(.numericText())
                .animation(progressAnimation, value: value)
            Text("kcal")
                .font(.caption2)
                .foregroundStyle(Color.circaInk2)
        }
    }

}

#Preview {
    DailyMacroDetailSheet(
        targetMacros: Macros(calories: 2400, protein: 170, carbs: 250, fat: 70),
        consumedMacros: Macros(calories: 1480, protein: 212, carbs: 80, fat: 26)
    )
}
