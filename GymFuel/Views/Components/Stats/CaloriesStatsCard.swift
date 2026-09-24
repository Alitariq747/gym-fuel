//
//  CaloriesStatsCard.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2025.
//

import SwiftUI

/// The week's food, from the `Week` artboard: seven bars against the target, and
/// underneath them how many days landed in range.
///
/// Below `minimumDaysForAverages` the footer says what is missing instead of
/// summarising two days as if they were a week — `Week · day 2`.
struct CaloriesStatsCard: View {
    let snapshot: StatsSnapshot
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var calorieTargetLabel: String? {
        guard let target = snapshot.dailyStats.compactMap(\.targetCalories).first else { return nil }
        return Int(target).formatted()
    }

    var body: some View {
        CircaCard {
            VStack(alignment: .leading, spacing: 16) {
                header
                chart
                CircaHairline(weight: .inCard)
                footer
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            CircaSectionLabel("What you ate")
            Spacer(minLength: 8)
            Text(headerMeta)
                .font(.circaMono)
                .monospacedDigit()
                .foregroundStyle(Color.circaInk3)
        }
    }

    private var headerMeta: String {
        guard snapshot.hasEnoughDaysForAverages else {
            return "\(snapshot.daysWithFood) of 7 days"
        }
        return "avg \(Int(snapshot.averageCalories.rounded()).formatted())"
    }

    private var chart: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(snapshot.dailyStats) { day in
                CalorieDayBar(day: day)
                    .frame(maxWidth: .infinity)
            }
        }
        .overlay(alignment: .top) {
            targetRule
                .offset(y: CalorieBarPlot.targetInset)
        }
    }

    /// Dashed, not dotted: the certainty rule is 1.5pt round dots under a
    /// number, and this is a reference line across a chart.
    private var targetRule: some View {
        GeometryReader { proxy in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0.5))
                path.addLine(to: CGPoint(x: proxy.size.width, y: 0.5))
            }
            .stroke(Color.circaDotted, style: StrokeStyle(lineWidth: 1, dash: [4, 5]))
        }
        .frame(height: 1)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var footer: some View {
        if snapshot.hasEnoughDaysForAverages {
            legend
        } else {
            Text("Averages appear once there are \(StatsSnapshot.minimumDaysForAverages) days to average.")
                .font(.circaCaption)
                .foregroundStyle(Color.circaInk3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var legend: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 14))
        return layout {
            legendItem(swatch: Color.circaInk, title: "\(snapshot.calorieTargetDays) days in range")
            legendItem(swatch: Color.circaAccentLarge, title: "\(snapshot.daysOutsideCalorieRange) outside")
            if let calorieTargetLabel {
                HStack(spacing: 6) {
                    targetRule.frame(width: 16)
                    legendText("target \(calorieTargetLabel)")
                }
            }
        }
    }

    private func legendItem(swatch: Color, title: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(swatch)
                .frame(width: 9, height: 9)
            legendText(title)
        }
    }

    private func legendText(_ title: String) -> some View {
        Text(title)
            .font(.circaMono)
            .monospacedDigit()
            .foregroundStyle(Color.circaInk3)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#if DEBUG
private extension StatsSnapshot {
    static func preview(_ calories: [Double], target: Double = 2400) -> StatsSnapshot {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        let days = calories.enumerated().compactMap { offset, kcal -> DailyStatsSnapshot? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return DailyStatsSnapshot(
                date: date, caloriesEaten: kcal, protein: 0, carbs: 0, fat: 0,
                targetCalories: target, targetProtein: 165, targetCarbs: 240, targetFat: 80
            )
        }
        var snapshot = StatsSnapshot.empty
        snapshot.dailyStats = days
        snapshot.calorieTargetDays = days.filter(\.isWithinCalorieRange).count
        let withFood = days.filter(\.hasFood)
        snapshot.averageCalories = withFood.isEmpty
            ? 0
            : withFood.reduce(0) { $0 + $1.caloriesEaten } / Double(withFood.count)
        return snapshot
    }
}

#Preview("Full week") {
    CaloriesStatsCard(snapshot: .preview([2310, 2480, 2180, 2395, 2760, 2520, 1940]))
        .padding()
        .circaPaper()
}

#Preview("Day 2") {
    CaloriesStatsCard(snapshot: .preview([2410, 1380, 0, 0, 0, 0, 0]))
        .padding()
        .circaPaper()
}
#endif
