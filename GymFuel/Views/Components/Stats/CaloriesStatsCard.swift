//
//  CaloriesStatsCard.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2025.
//

import SwiftUI

struct CaloriesStatsCard: View {
    let snapshot: StatsSnapshot
    @Environment(\.colorScheme) private var colorScheme

    private var calorieTargetLabel: String? {
        guard let target = snapshot.dailyStats.compactMap(\.targetCalories).first else { return nil }
        return Int(target).formatted()
    }

    private var totalCaloriesBurned: Double {
        snapshot.dailyStats.reduce(0) { $0 + $1.caloriesBurned }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            chart
            legend
            summaryRow
        }
        .padding(16)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(cardStroke, lineWidth: 1))
        .shadow(color: cardShadow, radius: 12, y: 6)
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }

    private var cardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)
    }

    private var cardShadow: Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.05)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Calories")
                .font(.headline.weight(.bold))
            Text("Eaten, burned, and target by day")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var chart: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(snapshot.dailyStats) { day in
                CalorieDayBar(day: day)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 150)
        .padding(.horizontal, 4)
        .padding(.top, 6)
        .overlay {
            GeometryReader { proxy in
                Path { path in
                    let y = proxy.size.height * 0.13
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                }
                .stroke(Color.primary.opacity(0.24), style: StrokeStyle(lineWidth: 1, dash: [4, 5]))
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 12) {
            legendItem(color: Color.fuelBlue.opacity(0.8), title: "Eaten")
            legendItem(color: Color.fuelRed.opacity(0.85), title: "Over")
            legendItem(color: Color.fuelOrange.opacity(0.65), title: "Burned")
            HStack(spacing: 5) {
                Capsule()
                    .stroke(Color.primary.opacity(0.28), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(width: 18, height: 6)
                Text("Target\(calorieTargetLabel.map { " = \($0)" } ?? "")")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 8) {
            summaryItem("Avg", "\(Int(snapshot.averageCalories).formatted())")
            summaryItem("Target days", "\(snapshot.calorieTargetDays) / 7")
            summaryItem("Burned", "\(Int(totalCaloriesBurned).formatted())")
        }
    }

    private func legendItem(color: Color, title: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func summaryItem(_ title: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.caption.weight(.bold))
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CaloriesStatsCard(snapshot: .empty)
        .padding()
}
