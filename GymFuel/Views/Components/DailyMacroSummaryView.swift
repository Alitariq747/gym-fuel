import SwiftUI

struct DailyMacroSummaryView: View {
    let targetMacros: Macros
    let consumedMacros: Macros
    let burnedCalories: Double
    @State private var isExpanded = false
    
    private var netCalories: Int {
        Int((consumedMacros.calories - burnedCalories).rounded())
    }
    
    private var remainingCalories: Int {
        Int((targetMacros.calories - consumedMacros.calories + burnedCalories).rounded())
    }
    
    private var remainingLabel: String {
        remainingCalories < 0 ? "over" : "left"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Text("🔥")
                    .font(.title3)
                Text("\(Int(consumedMacros.calories.rounded()))")
                    .font(.title3.weight(.bold))
                inlineMacro("P", value: consumedMacros.protein, color: .blue)
                inlineMacro("C", value: consumedMacros.carbs, color: .orange)
                inlineMacro("F", value: consumedMacros.fat, color: .pink)
                Spacer(minLength: 8)
                Image(systemName: "chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color(.quaternaryLabel).opacity(0.7), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 16, y: 8)
            .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            if isExpanded {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: 18) {
                        VStack(alignment: .leading, spacing: 4) {
                            calorieMeta("Eaten", value: Int(consumedMacros.calories.rounded()))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        calorieProgressRing
                        VStack(alignment: .trailing, spacing: 4) {
                            calorieMeta(
                                "Burned",
                                value: Int(burnedCalories.rounded()),
                                alignment: .trailing
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    HStack(spacing: 10) {
                        summaryTile("PRO", current: consumedMacros.protein, target: targetMacros.protein)
                        summaryTile("CARB", current: consumedMacros.carbs, target: targetMacros.carbs)
                        summaryTile("FAT", current: consumedMacros.fat, target: targetMacros.fat)
                    }
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color(.quaternaryLabel).opacity(0.55), lineWidth: 1)
                )
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isExpanded.toggle()
            }
        }
    }
    
    private func inlineMacro(_ label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 6) {
            Text("·")
                .font(.headline.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
            Text("\(Int(value.rounded()))")
                .font(.subheadline.weight(.semibold))
        }
    }

    private var calorieProgressRing: some View {
        let progress = min(max(consumedMacros.calories / max(targetMacros.calories, 1), 0), 1)
        let ringColor: Color =
            consumedMacros.calories > (targetMacros.calories + burnedCalories) ?
            .fuelRed : .fuelOrange

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
    
    private func summaryTile(
        _ short: String,
        current: Double,
        target: Double
    ) -> some View {
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
                    .foregroundStyle(.primary)
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
    
    private func calorieMeta(
        _ label: String,
        value: Int,
        alignment: HorizontalAlignment = .leading
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.headline.weight(.bold))
            Text("kcal")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }
}

#Preview {
    ZStack {
        DailyMacroSummaryView(
            targetMacros: Macros(calories: 2400, protein: 170, carbs: 250, fat: 70),
            consumedMacros: Macros(calories: 1480, protein: 212, carbs: 80, fat: 26),
            burnedCalories: 320
        )
        .padding()
    }
}
