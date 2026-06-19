import SwiftUI

struct DailyMacroSummaryView: View {
    let targetMacros: Macros
    let consumedMacros: Macros
    let burnedCalories: Double
    let onTap: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.orange)
                Text("\(Int(consumedMacros.calories.rounded()))")
                    .font(.title3.weight(.bold))
                inlineMacro("P", value: consumedMacros.protein, color: .blue)
                inlineMacro("C", value: consumedMacros.carbs, color: .orange)
                inlineMacro("F", value: consumedMacros.fat, color: .pink)
                Spacer(minLength: 8)
                Image(systemName: "ellipsis")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(.quaternaryLabel).opacity(0.7), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 16, y: 8)
            .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .onTapGesture(perform: onTap)
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

}

#Preview {
    ZStack {
        DailyMacroSummaryView(
            targetMacros: Macros(calories: 2400, protein: 170, carbs: 250, fat: 70),
            consumedMacros: Macros(calories: 1480, protein: 212, carbs: 80, fat: 26),
            burnedCalories: 320,
            onTap: {}
        )
        .padding()
    }
}
