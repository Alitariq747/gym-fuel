import SwiftUI

struct TimelineEntryRow: View {
    let entry: LogEntry
    var showsChevron: Bool = true

    private var feedback: LogEntryFeedback? { entry.feedback }
    private var exerciseEmoji: String {
        let title = entry.title.lowercased()

        if title.contains("run") || title.contains("treadmill") {
            return "🏃"
        }
        if title.contains("walk") || title.contains("hike") {
            return "🚶"
        }
        if title.contains("cycle") || title.contains("bike") {
            return "🚴"
        }
        if title.contains("swim") {
            return "🏊"
        }
        if title.contains("yoga") || title.contains("stretch") {
            return "🧘"
        }
        if title.contains("box") {
            return "🥊"
        }
        return "🏋️"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                if entry.type == .exercise {
                    Text(exerciseEmoji)
                        .font(.title3)
                        .frame(width: 38, height: 38)
                        .background(
                            Color(.systemGray6),
                            in: Circle()
                        )
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(entry.loggedAt.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(entry.title).font(.headline)
                    if entry.type == .exercise,
                       let estimatedCalories = feedback?.estimatedCalories {
                        infoChip("🔥 \(Int(estimatedCalories.rounded())) kcals burnt")
                    }
                }
                Spacer(minLength: 12)
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            if let macros = feedback?.macros {
                HStack(spacing: 12) {
                    macroStat("CAL", value: "\(Int(macros.calories.rounded()))")
                    macroStat("PRO", value: "\(Int(macros.protein.rounded()))g")
                    macroStat("CARB", value: "\(Int(macros.carbs.rounded()))g")
                    macroStat("FAT", value: "\(Int(macros.fat.rounded()))g")
                }
            }
            if let explanation = feedback?.explanation, !explanation.isEmpty {
                Divider()
                    .padding(8)
                HStack(spacing: 12) {
                    if let goalFitScore = feedback?.goalFitScore {
                        let scoreColor = goalFitScore >= 60 ? Color.fuelGreen : Color.fuelRed

                        ZStack {
                            Circle()
                                .fill(Color(.systemBackground))
                                .overlay(Circle().stroke(scoreColor))
                            Text("\(goalFitScore)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(scoreColor)
                        }
                        .frame(width: 42, height: 42)
                    }

                    Text(explanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)
//                .background(
//                    Color(.systemBackground),
//                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
//                )
//                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.quaternaryLabel)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(.quaternaryLabel), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func infoChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemFill), in: Capsule())
    }

    @ViewBuilder
    private func macroStat(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#Preview("Food") {
    TimelineEntryRow(
        entry: LogEntry(
            userId: "preview",
            type: .food,
            title: "Chicken Burrito Bowl",
            rawInput: "Chicken burrito bowl",
            feedback: LogEntryFeedback(
                explanation: "High protein and decent satiety make this easier to fit into a cut.",
                assumptions: [],
                confidence: 0.84,
                estimatedCalories: nil,
                macros: Macros(calories: 620, protein: 44, carbs: 52, fat: 20),
                goalFitScore: 68,
                rebalanceHint: nil
            )
        )
    )
    .padding()
}

#Preview("Exercise") {
    TimelineEntryRow(
        entry: LogEntry(
            userId: "preview",
            type: .exercise,
            title: "Treadmill Run",
            rawInput: "45 min treadmill run",
            feedback: LogEntryFeedback(
                explanation: "Moderate-duration cardio session with a reasonable calorie burn estimate.",
                assumptions: [],
                confidence: 0.79,
                estimatedCalories: 410,
                macros: nil,
                goalFitScore: nil,
                rebalanceHint: nil
            )
        )
    )
    .padding()
}
