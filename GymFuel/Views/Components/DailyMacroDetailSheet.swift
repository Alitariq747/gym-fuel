import SwiftUI

struct DailyMacroDetailSheet: View {
    let targetMacros: Macros
    let consumedMacros: Macros
    let burnedCalories: Double

    private var remainingCalories: Int {
        Int((targetMacros.calories - consumedMacros.calories + burnedCalories).rounded())
    }

    private var remainingLabel: String {
        remainingCalories < 0 ? "over" : "left"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(Color.secondary.opacity(0.22))
                .frame(width: 42, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            Text("Details")
                .font(.title3.weight(.bold))

            HStack(alignment: .center, spacing: 18) {
                calorieMeta("Eaten", value: Int(consumedMacros.calories.rounded()))
                    .frame(maxWidth: .infinity, alignment: .leading)

                calorieProgressRing

                calorieMeta("Burned", value: Int(burnedCalories.rounded()), alignment: .trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            HStack(spacing: 10) {
                summaryTile("PRO", current: consumedMacros.protein, target: targetMacros.protein)
                summaryTile("CARB", current: consumedMacros.carbs, target: targetMacros.carbs)
                summaryTile("FAT", current: consumedMacros.fat, target: targetMacros.fat)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var calorieProgressRing: some View {
        let progress = min(max(consumedMacros.calories / max(targetMacros.calories, 1), 0), 1)
        let ringColor: Color = consumedMacros.calories > (targetMacros.calories + burnedCalories) ? .fuelRed : .fuelOrange

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
                Text(remainingLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 108, height: 108)
    }

    private func summaryTile(_ short: String, current: Double, target: Double) -> some View {
        let progress = min(max(current / max(target, 1), 0), 1)
        let baseColor: Color = switch short {
        case "PRO": .fuelBlue
        case "CARB": .fuelGreen
        default: .pink
        }
        let fillColor: Color = current > target ? .fuelRed : baseColor

        return VStack(alignment: .leading, spacing: 6) {
            Text(short)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(Int(current.rounded()))")
                    .font(.headline.weight(.bold))
                Text("/ \(Int(target.rounded()))g")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Capsule()
                .fill(fillColor.opacity(0.10))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(fillColor.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .scaleEffect(x: progress, y: 1, anchor: .leading)
                }
                .frame(height: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemBackground).opacity(0.8), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.035), radius: 8, y: 4)
    }

    private func calorieMeta(_ label: String, value: Int, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.headline.weight(.bold))
            Text("kcal")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    DailyMacroDetailSheet(
        targetMacros: Macros(calories: 2400, protein: 170, carbs: 250, fat: 70),
        consumedMacros: Macros(calories: 1480, protein: 212, carbs: 80, fat: 26),
        burnedCalories: 320
    )
}
