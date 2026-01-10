//
//  FuelScoreCard.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/01/2026.
//

import SwiftUI

import SwiftUI

struct FuelScoreCard: View {
    let dayLog: DayLog

    // MARK: - Derived data

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

    // MARK: - Score bands & messages

    private enum ScoreBand {
        case noData
        case offPlan
        case needsWork
        case solid
        case dialedIn

        var title: String {
            switch self {
            case .noData:    return "No score yet"
            case .offPlan:   return "Off plan"
            case .needsWork: return "Needs work"
            case .solid:     return "Solid"
            case .dialedIn:  return "Dialed in"
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
        // Case 1: no score yet
        guard hasScore else {
            if isTrainingDay {
                return "Log at least one pre- or post-workout meal to start today’s Fuel Score."
            } else {
                return "Log your meals to see how well you’re fueling recovery on this rest day."
            }
        }

        // Case 2: we have a score – branch on band + training/rest
        switch (scoreBand, isTrainingDay) {
        case (.dialedIn, true):
            return "You’re nailing both macros and timing around your session."
        case (.solid, true):
            return "Good fuel overall. A small tweak to timing or protein would push this higher."
        case (.needsWork, true):
            return "You’re missing either key macros or the timing around your workout."
        case (.offPlan, true):
            return "Today’s fuel hasn’t supported your session well. Treat this as feedback, not judgment."

        case (.dialedIn, false):
            return "Great macro balance for recovery. Protein and total calories are on point."
        case (.solid, false):
            return "Solid rest-day fueling. You’re supporting recovery without overshooting."
        case (.needsWork, false):
            return "Rest-day macros could be tighter, especially protein and total calories."
        case (.offPlan, false):
            return "Today’s intake is far from your rest-day targets. Tomorrow is a fresh start."
        default:
            return ""
        }
    }

    // MARK: - Gauge helpers

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

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fuel Score")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(scoreBand.title)
                        .font(.headline)
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
            HStack(spacing: 16) {
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(
                            Color(.systemGray5),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
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
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    // Center text
                    VStack(spacing: 2) {
                        Text(hasScore ? "\(totalScore)" : "--")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("out of 100")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 110, height: 110)

                // Message on the right
                Text(bandMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

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
                            value: macroScore
                        )
                    }

                    if isTrainingDay, let timingScore {
                        metricChip(
                            systemImage: "clock.fill",
                            title: "Timing",
                            value: timingScore
                        )
                    } else if !isTrainingDay, let macroScore {
                        // For rest day, show “Recovery” chip based on macro adherence
                        metricChip(
                            systemImage: "moon.zzz.fill",
                            title: "Recovery",
                            value: macroScore
                        )
                    }

                }
                .frame(maxWidth: .infinity)
            } else {
                Text("Fuel Score appears once you’ve logged some food for this day.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.95))
        )
//        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
    }


    private func metricChip(
        systemImage: String,
        title: String,
        value: Int
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            VStack(alignment: .center, spacing: 0) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(value)")
                    .font(.caption.weight(.semibold))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 18)
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

