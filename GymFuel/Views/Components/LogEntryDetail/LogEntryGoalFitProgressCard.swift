import SwiftUI

struct GoalFitProgressCard: View {
    let score: Int
    let goalType: GoalType?
    @Environment(\.colorScheme) private var colorScheme

    private var progress: Double {
        min(max(Double(score) / 100, 0), 1)
    }

    private var goal: GoalType {
        goalType ?? .defaultValue
    }

    private var scoreColor: Color {
        if score > 80 { return .fuelGreen }
        if score < 50 { return .fuelRed }
        return .fuelBlue
    }

    private var title: String {
        "\(goal.displayName) fit score"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: goal.symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(scoreColor)
                    .frame(width: 34, height: 34)
                    .background(scoreColor.opacity(colorScheme == .dark ? 0.18 : 0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                Spacer()

                Text("\(score)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(scoreColor)
                    .monospacedDigit()
            }

            Capsule()
                .fill(scoreColor.opacity(0.10))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(scoreColor.opacity(0.75))
                        .scaleEffect(x: progress, y: 1, anchor: .leading)
                }
                .frame(height: 5)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground).opacity(colorScheme == .dark ? 0.72 : 0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(scoreColor.opacity(colorScheme == .dark ? 0.18 : 0.10), lineWidth: 1)
        }
    }
}
