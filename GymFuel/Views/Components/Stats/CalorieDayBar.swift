//
//  CalorieDayBar.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2025.
//

import SwiftUI

/// The plot the week's bars and the dashed target line share. `CaloriesStatsCard`
/// draws the line, the bars draw themselves, and both need the same two numbers
/// for the line to land on the target rather than near it.
enum CalorieBarPlot {
    static let height: CGFloat = 112
    /// How far above target a bar can draw before it clips.
    static let headroom: Double = 1.15
    /// Distance from the top of the plot down to the target line.
    static var targetInset: CGFloat { height * (1 - 1 / headroom) }
    static let barRadius: CGFloat = 5
}

/// One day of the week's food, from the `Week` artboard. A day with nothing on
/// it is a dashed outline up to the target rather than a zero-height bar —
/// `Week · day 2` — so five days still to come read as waiting, not as fasting.
struct CalorieDayBar: View {
    let day: DailyStatsSnapshot
    @Environment(\.dynamicTypeSize) private var typeSize

    private var fillRatio: Double {
        guard let target = day.targetCalories, target > 0 else { return 0 }
        return min(day.caloriesEaten / target, CalorieBarPlot.headroom) / CalorieBarPlot.headroom
    }

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: CalorieBarPlot.barRadius,
            topTrailingRadius: CalorieBarPlot.barRadius,
            style: .continuous
        )
    }

    var body: some View {
        VStack(spacing: 7) {
            plot
            Text(day.date.formatted(.dateTime.weekday(.narrow)))
                .font(.circaMono)
                .foregroundStyle(day.hasFood ? Color.circaInk3 : Color.circaDotted)
            if !typeSize.isAccessibilitySize {
                Text(day.hasFood ? Int(day.caloriesEaten.rounded()).formatted() : "—")
                    .font(.circaMono)
                    .monospacedDigit()
                    .foregroundStyle(day.hasFood ? Color.circaInk3 : Color.circaDotted)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var plot: some View {
        ZStack(alignment: .bottom) {
            if day.hasFood {
                shape
                    .fill(day.isWithinCalorieRange ? Color.circaInk : Color.circaAccentLarge)
                    .frame(height: max(6, CalorieBarPlot.height * fillRatio))
            } else {
                // Stops at the target line, so the outline says what the day holds.
                shape
                    .strokeBorder(Color.circaRule, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .frame(height: CalorieBarPlot.height / CalorieBarPlot.headroom)
            }
        }
        .frame(height: CalorieBarPlot.height, alignment: .bottom)
    }

    private var accessibilityLabel: String {
        let weekday = day.date.formatted(.dateTime.weekday(.wide))
        guard day.hasFood else { return "\(weekday), nothing logged" }

        let eaten = Int(day.caloriesEaten.rounded()).formatted()
        return "\(weekday), \(eaten) calories, \(day.isWithinCalorieRange ? "in range" : "outside range")"
    }
}
