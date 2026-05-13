//
//  StatsActivitySummaryRow.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2025.
//

import SwiftUI

struct StatsActivitySummaryRow: View {
    let foodLogs: Int
    let workoutLogs: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            statTile(title: "Meals", value: "\(foodLogs)", emoji: "🥗")
            statTile(title: "Workouts", value: "\(workoutLogs)", emoji: "🏋️")
        }
    }

    private func statTile(title: String, value: String, emoji: String) -> some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(.headline)
                .frame(width: 34, height: 34)
                .background(Color(.tertiarySystemFill), in: Circle())
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(value)
                    .font(.title3.weight(.bold))
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(tileBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(tileStroke, lineWidth: 1))
        .shadow(color: tileShadow, radius: 10, y: 5)
    }

    private var tileBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }

    private var tileStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)
    }

    private var tileShadow: Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.05)
    }
}

#Preview {
    StatsActivitySummaryRow(foodLogs: 18, workoutLogs: 3)
        .padding()
}
