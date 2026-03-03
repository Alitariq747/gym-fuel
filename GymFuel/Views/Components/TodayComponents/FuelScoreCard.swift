//
//  FuelScoreCard.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/01/2026.
//



import SwiftUI

struct FuelScoreCard: View {
    let dayLog: DayLog


    private var fuelScore: FuelScore? {
        dayLog.fuelScore
    }

    private var isTrainingDay: Bool {
        dayLog.isTrainingDay
    }

    private var totalScore: Int {
        fuelScore?.total ?? 0
    }

    private var macroScore: Int? {
        fuelScore?.macroAdherence
    }

    private var timingScore: Int? {
        fuelScore?.timingAdherence
    }

    private var hasScore: Bool {
        fuelScore != nil
    }


    private enum ScoreBand {
        case noData
        case offPlan
        case needsWork
        case solid
        case dialedIn

        var title: String {
            switch self {
            case .noData:    return "No score yet"
            case .offPlan:   return "Off track"
            case .needsWork: return "Getting there"
            case .solid:     return "On track"
            case .dialedIn:  return "Crushing it"
            }
        }
    }

    private var scoreBand: ScoreBand {
        guard hasScore else { return .noData }

        switch totalScore {
        case 80...100:
            return .dialedIn
        case 60..<80:
            return .solid
        case 40..<60:
            return .needsWork
        default:
            return .offPlan
        }
    }

    private var bandMessage: String {
        guard hasScore else {
            if isTrainingDay {
                return "Log a pre- or post-workout meal to generate today’s score."
            } else {
                return "Log a meal to get your recovery score for today."
            }
        }

        switch (scoreBand, isTrainingDay) {
        case (.dialedIn, true):
            return "Great fuel around your session. Keep this rhythm."
        case (.solid, true):
            return "Solid fuel. A small timing or protein tweak gets you higher."
        case (.needsWork, true):
            return "A bit off on macros or timing today—adjust next meal."
        case (.offPlan, true):
            return "Fueling didn’t support the session. Reset with your next meal."

        case (.dialedIn, false):
            return "Recovery nutrition is strong. Protein and totals look great."
        case (.solid, false):
            return "Good rest-day balance. Recovery is supported."
        case (.needsWork, false):
            return "Rest-day macros are a bit loose—tighten protein and totals."
        case (.offPlan, false):
            return "Rest-day intake is off target. Aim to reset next meal."
        default:
            return ""
        }
    }


    private var progress: Double {
        guard hasScore else { return 0 }
        return min(max(Double(totalScore) / 100.0, 0), 1)
    }

    private var gaugeColor: Color {
        switch scoreBand {
        case .noData:
            return Color(.systemGray4)
        case .offPlan:
            return .red
        case .needsWork:
            return .orange
        case .solid:
            return .yellow
        case .dialedIn:
            return .green
        }
    }

    private var trainingBadgeText: String {
        isTrainingDay ? "Training day" : "Rest day"
    }


    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fuel Score")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(scoreBand.title)
                        .font(.headline.weight(.semibold))
                }

                Spacer()

                Text(trainingBadgeText.uppercased())
                    .font(.caption2.weight(.semibold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray6))
                    )
            }

            // Gauge + message
            HStack(spacing: 12) {
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(
                            Color(.systemGray5),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    gaugeColor.opacity(0.4),
                                    gaugeColor
                                ]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.35), value: progress)

                    // Center text
                    VStack(spacing: 2) {
                        Text(hasScore ? "\(totalScore)" : "--")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("of 100")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 84, height: 84)

                // Message on the right
                Text(bandMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)

                Spacer(minLength: 0)
            }

            // Macro / timing chips
            if hasScore {
                Divider()
                HStack(alignment: .center, spacing: 8) {
                    if let macroScore {
                        metricChip(
                            systemImage: "flame.fill",
                            title: "Macros",
                            value: macroScore,
                            tint: Color("FuelOrange")
                        )
                    }

                    if isTrainingDay, let timingScore {
                        metricChip(
                            systemImage: "clock.fill",
                            title: "Timing",
                            value: timingScore,
                            tint: Color("FuelBlue")
                        )
                    } else if !isTrainingDay, let macroScore {
                        // For rest day, show “Recovery” chip based on macro adherence
                        metricChip(
                            systemImage: "moon.zzz.fill",
                            title: "Recovery",
                            value: macroScore,
                            tint: Color("FuelGreen")
                        )
                    }

                }
                .frame(maxWidth: .infinity)
            } else {
                Text("Score appears after your first logged meal.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }


    private func metricChip(
        systemImage: String,
        title: String,
        value: Int,
        tint: Color
    ) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)

            VStack(alignment: .center, spacing: 0) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(value)")
                    .font(.caption.weight(.semibold))
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    ZStack {
        AppBackground()
        FuelScoreCard(dayLog: DayLog.demoTrainingDay)
            .padding()
    }
}
