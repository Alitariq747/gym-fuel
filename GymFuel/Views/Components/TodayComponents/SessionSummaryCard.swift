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
        HStack(spacing: 12) {
            Text(dayLog.isTrainingDay ? "🏋️" : "😴")
                .font(.headline)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(dayLog.isTrainingDay ? Color.fuelRed.opacity(0.15) : Color.fuelOrange.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(sessionTitle)
                    .font(.headline.weight(.semibold))

                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(timeLabel ?? "Prioritize rest today.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Image(systemName: "pencil")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ChipView(text: intensityLabel, tint: intensityColor)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
        )
    }

    private var sessionTitle: String {
        if dayLog.isTrainingDay {
            let session = dayLog.sessionType?.displayName ?? "Training"
            return session
        }
        return "Rest & Recovery"
    }

    private var intensityLabel: String {
        dayLog.isTrainingDay
        ? (dayLog.trainingIntensity?.displayName ?? "Normal")
        : "Recovery"
    }

    private var intensityColor: Color {
        let intensity = dayLog.trainingIntensity ?? .normal

        switch intensity {
        case .recovery:
            return Color.fuelOrange
        case .normal:
            return Color.fuelBlue
        case .hard:
            return Color("FuelGreen")
        case .allOut:
            return Color.fuelRed
        }
    }

    private var timeLabel: String? {
        guard let start = dayLog.sessionStart else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: start)
    }
}

private struct ChipView: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(tint.opacity(0.12))
            )
            .foregroundStyle(tint)
    }
}


#Preview {
    ZStack {
        AppBackground()
        SessionSummaryCard(dayLog: DayLog.demoRestDay)
    }
}
