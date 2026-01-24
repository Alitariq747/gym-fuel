//
//  DayFuelStatsRow.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 21/01/2026.
//

import SwiftUI

struct DayFuelStatsRow: View {
    let row: DayFuelRow
    private let calendar = Calendar.current

    // Display helpers
    private var dayLabel: String {
        row.date.formatted(.dateTime.weekday(.abbreviated))
    }

    private var sessionLabel: String {
        if row.isTrainingDay {
            row.sessionType?.displayName ?? "Training"
        } else {
            "Rest Day"
        }
    }

    private var intensityLabel: String {
        if row.isTrainingDay {
            row.intensity?.displayName ?? "—"
        } else {
            "—"
        }
    }

    private var scoreLabel: String {
        if let score = row.fuelScore {
            "🔥 \(score)"
        } else {
            "0"
        }
    }

    private var scoreColor: Color {
        let total = row.fuelScore ?? 0
        return total >= 75 ? .fuelGreen : .fuelRed
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {

            // Column 1: dot + day
            HStack(spacing: 6) {
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundStyle(Color(.systemGray))

                Text(dayLabel)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(width: 60, alignment: .leading)

            // Column 2: session type (or "Rest Day")
            Text(sessionLabel)
                .font(.subheadline)
                .frame(width: 90, alignment: .leading)

            // Column 3: intensity
            Text(intensityLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)

            Spacer()

            // Column 4: score
            Text(scoreLabel)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 6)

    }
}

#Preview {
    VStack(spacing: 8) {
        DayFuelStatsRow(
            row: DayFuelRow(
                date: Date(),
                fuelScore: 82, isTrainingDay: true,
                intensity: .recovery,
                sessionType: .hypertrophy
            )
        )
        DayFuelStatsRow(
            row: DayFuelRow(
                date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
                fuelScore: nil, isTrainingDay: false,
                intensity: nil,
                sessionType: nil
            )
        )
    }
    .padding()
}
