//
//  SessionSummaryCard.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/01/2026.
//

import SwiftUI

struct SessionSummaryCard: View {
    let dayLog: DayLog

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                Text(dayLog.isTrainingDay ? "🏋️" : "😴")
                     .font(.headline)
                     .padding(10)
                     .background(Color(.systemGray5), in: Circle())

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(dayLog.isTrainingDay ? "TODAY'S SESSION" : "TODAY'S RECOVERY")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text(sessionTitle)
                            .font(.headline.bold())
                    }

                    Text(sessionSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    timingRow
                        .opacity(dayLog.isTrainingDay ? 1 : 0)
                        .accessibilityHidden(!dayLog.isTrainingDay)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.9))
        )
        .shadow(
            color: Color.black.opacity(0.12),
            radius: 8,
            x: 0, y: 4
        )
    }

    private var sessionTitle: String {
        if dayLog.isTrainingDay {
            let intensity = dayLog.trainingIntensity?.displayName ?? "Normal"
            let session = dayLog.sessionType?.displayName ?? "Hypertrophy"
            return "\(intensity) day - \(session)"
        }
        return "Rest day - Recovery"
    }

    private var sessionSubtitle: String {
        dayLog.isTrainingDay
        ? "Fuel around your session today."
        : "Prioritize sleep and rest today."
    }

    private var intensityColor: Color {
        let intensity = dayLog.trainingIntensity ?? .normal

        switch intensity {
        case .recovery:
            return Color(.systemGray2)
        case .normal:
            return Color.blue
        case .hard:
            return Color.green
        case .allOut:
            return Color.red
        }
    }

    private var intensityBars: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .frame(width: 4, height: 14)
            }
        }
        .foregroundStyle(intensityColor)
    }

    private var timingRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(timeLabel ?? "—")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 4) {
                Text("Intensity: ")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                intensityBars
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

        }
    }

    private var timeLabel: String? {
        guard let start = dayLog.sessionStart else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: start)
    }
}


#Preview {
    ZStack {
        AppBackground()
        SessionSummaryCard(dayLog: DayLog.demoTrainingDay)
    }
}
