//
//  StatsMacroDaysCard.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 04/10/2026.
//

import SwiftUI

/// Each day's protein, carbs and fat, for a week with too few days to average.
/// It lists what was eaten and averages nothing, so it can show from the first
/// day; `StatsView` swaps in the daily averages at `minimumDaysForAverages`.
struct StatsMacroDaysCard: View {
    let snapshot: StatsSnapshot
    @Environment(\.dynamicTypeSize) private var typeSize

    private static let macroNames = ["Protein", "Carbs", "Fat"]

    private var days: [DailyStatsSnapshot] { snapshot.dailyStats.filter(\.hasFood) }

    private var targetGrams: [Int]? {
        guard let day = snapshot.dailyStats.first,
              let protein = day.targetProtein, let carbs = day.targetCarbs, let fat = day.targetFat
        else { return nil }
        return [protein, carbs, fat].map { Int($0.rounded()) }
    }

    var body: some View {
        CircaCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    CircaSectionLabel("Day by day")
                    Spacer(minLength: 8)
                    Text("grams")
                        .font(.circaMono)
                        .foregroundStyle(Color.circaInk3)
                }
                if typeSize.isAccessibilitySize { stacked } else { table }
            }
        }
    }

    private var table: some View {
        Grid(alignment: .trailing, horizontalSpacing: 14, verticalSpacing: 9) {
            GridRow {
                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                ForEach(Self.macroNames, id: \.self) { mono($0, tint: .circaInk3).fixedSize() }
            }
            .accessibilityHidden(true)
            ForEach(days) { day in
                tableRow(day.date.formatted(.dateTime.weekday(.abbreviated)), grams: grams(of: day), tint: .circaInk2)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(spoken(day.date.formatted(.dateTime.weekday(.wide)), grams(of: day)))
            }
            if let targetGrams {
                CircaHairline(weight: .inCard)
                tableRow("Target", grams: targetGrams, tint: .circaInk3)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(spoken("Daily target", targetGrams))
            }
        }
    }

    private func tableRow(_ title: String, grams: [Int], tint: Color) -> some View {
        GridRow {
            mono(title, tint: .circaInk3)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(grams.indices, id: \.self) { mono(grams[$0].formatted(), tint: tint).fixedSize() }
        }
    }

    private var stacked: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(days) { day in
                stackedRow(day.date.formatted(.dateTime.weekday(.wide)), grams: grams(of: day))
            }
            if let targetGrams {
                CircaHairline(weight: .inCard)
                stackedRow("Daily target", grams: targetGrams)
            }
        }
    }

    private func stackedRow(_ title: String, grams: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.circaRow)
                .foregroundStyle(Color.circaInk)
            mono(
                zip(Self.macroNames, grams).map { "\($0) \($1.formatted())" }.joined(separator: " · "),
                tint: .circaInk2
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken(title, grams))
    }

    private func mono(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.circaMono)
            .monospacedDigit()
            .foregroundStyle(tint)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func grams(of day: DailyStatsSnapshot) -> [Int] {
        [day.protein, day.carbs, day.fat].map { Int($0.rounded()) }
    }

    private func spoken(_ title: String, _ grams: [Int]) -> String {
        let macros = zip(Self.macroNames, grams).map { "\($0) \($1) grams" }
        return "\(title), \(macros.joined(separator: ", "))"
    }
}

#if DEBUG
#Preview("Day 2") {
    let start = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
    let eaten: [(Double, Double, Double)] = [(142, 260, 71), (98, 150, 48)] + Array(repeating: (0, 0, 0), count: 5)
    var snapshot = StatsSnapshot.empty
    snapshot.dailyStats = eaten.enumerated().map { offset, macros in
        DailyStatsSnapshot(
            date: Calendar.current.date(byAdding: .day, value: offset, to: start) ?? start,
            caloriesEaten: macros.0 * 4 + macros.1 * 4 + macros.2 * 9,
            protein: macros.0, carbs: macros.1, fat: macros.2,
            targetCalories: 2400, targetProtein: 165, targetCarbs: 240, targetFat: 80
        )
    }
    return StatsMacroDaysCard(snapshot: snapshot)
        .padding()
        .circaPaper()
}
#endif
