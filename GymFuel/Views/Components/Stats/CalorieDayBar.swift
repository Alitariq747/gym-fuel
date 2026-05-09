//
//  CalorieDayBar.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2025.
//

import SwiftUI

struct CalorieDayBar: View {
    let day: DailyStatsSnapshot

    private var eatenRatio: Double {
        guard let target = day.targetCalories, target > 0 else { return 0 }
        return min(day.caloriesEaten / target, 1.15)
    }

    private var hasBurnedCalories: Bool {
        day.caloriesBurned > 0
    }

    private var isOverEffectiveTarget: Bool {
        guard let target = day.targetCalories else { return false }
        return day.caloriesEaten > target + day.caloriesBurned
    }

    private var eatenColor: Color {
        isOverEffectiveTarget ? Color.fuelRed.opacity(0.85) : Color.fuelBlue.opacity(0.8)
    }

    private var burnedAllowanceRatio: Double {
        guard let target = day.targetCalories, target > 0 else { return 0 }
        return min(day.caloriesBurned / target, 0.28)
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                let height = proxy.size.height
                let targetHeight = height / 1.15
                let fillHeight = day.caloriesEaten > 0 ? max(8, targetHeight * eatenRatio) : 0
                let burnedHeight = max(4, targetHeight * burnedAllowanceRatio)
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color(.tertiarySystemFill))
                    if hasBurnedCalories { RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.fuelOrange.opacity(0.65)).frame(height: burnedHeight).offset(y: -targetHeight) }
                    RoundedRectangle(cornerRadius: 8, style: .continuous).fill(eatenColor).frame(height: fillHeight)
                }
            }
            Text(day.date.formatted(.dateTime.weekday(.narrow))).font(.caption2.weight(.bold)).foregroundStyle(.secondary)
        }
    }
}
