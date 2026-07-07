import SwiftUI

struct TimelineEntryMetricsView: View {
    let entry: LogEntry
    let state: TimelineEntryRowState
    let exerciseSymbol: String
    let showRevealedCalories: Bool
    let showRevealedProtein: Bool
    let showRevealedCarbs: Bool
    let showRevealedFat: Bool
    let showRevealedGoalFit: Bool

    private var exerciseEstimate: ExerciseEstimate? {
        state.feedback?.exercise
    }

    var body: some View {
        if entry.type == .exercise {
            exerciseMetricRows()
        } else if let macros = state.feedback?.macros, entry.type == .food,
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
                    secondaryMetricStat(symbol: "fish", value: "\(Int(macros.protein.rounded()))g", color: .fuelBlue)
                }
                if showRevealedCarbs {
                    secondaryMetricStat(symbol: "leaf.fill", value: "\(Int(macros.carbs.rounded()))g", color: .fuelGreen)
                }
                if showRevealedFat {
                    secondaryMetricStat(symbol: "drop.fill", value: "\(Int(macros.fat.rounded()))g", color: .pink)
                }
                if showRevealedGoalFit, let goalFitScore = state.feedback?.goalFitScore {
                    Spacer(minLength: 8)
                    goalFitScoreBadge(score: goalFitScore)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
        }
        .padding(.top, 1)
    }

    @ViewBuilder
    private func exerciseMetricRows() -> some View {
        if showRevealedCalories || exerciseEstimate != nil {
            VStack(alignment: .leading, spacing: 6) {
                if showRevealedCalories, let estimatedCalories = state.feedback?.estimatedCalories {
                    primaryMetricStat(symbol: "flame.fill", value: "\(Int(estimatedCalories.rounded())) Burned", color: .primary)
                }
                if let exerciseEstimate {
                    HStack(spacing: 7) {
                        exerciseSecondaryMetricStat(
                            symbol: exerciseSymbol,
                            value: displayActivityType(exerciseEstimate.activityType)
                        )
                        exerciseSecondaryMetricStat(
                            symbol: "clock.fill",
                            value: "\(exerciseEstimate.durationMinutes) min"
                        )
                        exerciseSecondaryMetricStat(
                            symbol: intensitySymbol(for: exerciseEstimate.intensity),
                            value: displayIntensity(exerciseEstimate.intensity)
                        )
                    }
                    .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                }
            }
            .padding(.top, 1)
        }
    }

    @ViewBuilder
    private func primaryMetricStat(symbol: String, value: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Image(systemName: symbol)
                .font(.caption.weight(.regular))
                .foregroundStyle(color)
            Text(value)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
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
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }

    @ViewBuilder
    private func exerciseSecondaryMetricStat(symbol: String, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.caption2.weight(.regular))
                .foregroundStyle(.primary)
                .frame(width: 14, height: 14)
            Text(value)
                .font(.caption2.weight(.regular))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }

    @ViewBuilder
    private func goalFitScoreBadge(score: Int) -> some View {
        let color = scoreColor(for: score)
        let symbolName = state.feedback?.goalType?.symbolName ?? GoalType.defaultValue.symbolName

        HStack(spacing: 4) {
            Image(systemName: symbolName)
                .font(.caption2.weight(.regular))
            Text("\(score)")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .frame(height: 30)
        .background(color.opacity(0.11), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(color.opacity(0.14), lineWidth: 1)
        }
    }

    private func displayActivityType(_ value: String) -> String {
        switch value {
        case "walking":
            return "Walking"
        case "running":
            return "Running"
        case "cycling":
            return "Cycling"
        case "strength_training":
            return "Strength"
        case "hiit":
            return "HIIT"
        case "swimming":
            return "Swimming"
        case "sports":
            return "Sports"
        case "rowing":
            return "Rowing"
        case "hiking":
            return "Hiking"
        case "yoga":
            return "Yoga"
        default:
            return "Exercise"
        }
    }

    private func displayIntensity(_ value: String) -> String {
        switch value {
        case "low":
            return "Low"
        case "high":
            return "High"
        default:
            return "Moderate"
        }
    }

    private func intensitySymbol(for value: String) -> String {
        switch value {
        case "low":
            return "gauge.low"
        case "high":
            return "gauge.high"
        default:
            return "gauge.medium"
        }
    }

    private func scoreColor(for score: Int) -> Color {
        if score > 80 { return .fuelGreen }
        if score < 50 { return .fuelRed }
        return .fuelBlue
    }
}
