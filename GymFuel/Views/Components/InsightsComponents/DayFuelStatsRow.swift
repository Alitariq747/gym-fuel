//
//  DayFuelStatsRow.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 21/01/2026.
//

import SwiftUI

struct DayFuelStatsRow: View {
    let row: DayFuelRow

    // Display helpers
    private var dayLabel: String {
        row.date.formatted(.dateTime.weekday(.abbreviated))
    }

    private var sessionLabel: String {
        if !row.hasLog {
            return "No log"
        }
        return row.isTrainingDay
            ? (row.sessionType?.displayName ?? "Training")
            : "Rest Day"
    }

    private var intensityLabel: String {
        if !row.hasLog {
            return "—"
        }
        return row.isTrainingDay
            ? (row.intensity?.displayName ?? "—")
            : "—"
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
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    VStack(spacing: 8) {
        DayFuelStatsRow(
            row: DayFuelRow(
                date: Date(),
                isTrainingDay: true,
                intensity: .recovery,
                sessionType: .push,
                hasLog: true
            )
        )
        DayFuelStatsRow(
            row: DayFuelRow(
                date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
                isTrainingDay: false,
                intensity: nil,
                sessionType: nil,
                hasLog: false
            )
        )
    }
    .padding()
}
