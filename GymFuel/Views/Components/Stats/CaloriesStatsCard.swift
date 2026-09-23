//
//  CaloriesStatsCard.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2025.
//

import SwiftUI

struct CaloriesStatsCard: View {
    let snapshot: StatsSnapshot
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var calorieTargetLabel: String? {
        guard let target = snapshot.dailyStats.compactMap(\.targetCalories).first else { return nil }
        return Int(target).formatted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            chart
            legend
            summaryRow
        }
        .padding(16)
        .background(Color.circaCard, in: RoundedRectangle(cornerRadius: Circa.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Circa.Radius.card, style: .continuous).stroke(Color.circaCardBorder, lineWidth: 1))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Calories")
                .font(.headline.weight(.bold))
            Text("Eaten and target by day")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.circaInk2)
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
                .stroke(Color.circaDotted, style: StrokeStyle(lineWidth: 1, dash: [4, 5]))
            }
        }
    }

    private var legend: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            legendItem(color: Color.circaInk, title: "Eaten")
            legendItem(color: Color.circaAccentLarge, title: "Over")
            HStack(spacing: 5) {
                Capsule()
                    .stroke(Color.circaDotted, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(width: 18, height: 6)
                Text("Target\(calorieTargetLabel.map { " = \($0)" } ?? "")")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.circaInk2)
            }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 8) {
            summaryItem("Avg", "\(Int(snapshot.averageCalories).formatted())")
            summaryItem("Target days", "\(snapshot.calorieTargetDays) / 7")
        }
    }

    private func legendItem(color: Color, title: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.circaInk2)
        }
    }

    private func summaryItem(_ title: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.caption.weight(.bold))
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.circaInk2)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CaloriesStatsCard(snapshot: .empty)
        .padding()
}
