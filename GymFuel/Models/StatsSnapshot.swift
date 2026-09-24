//
//  StatsSnapshot.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2026.
//

import Foundation

struct DailyStatsSnapshot: Identifiable, Equatable {
    var id: Date { date }
    let date: Date
    var caloriesEaten: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var targetCalories: Double?
    var targetProtein: Double?
    var targetCarbs: Double?
    var targetFat: Double?
}

struct StatsSnapshot: Equatable {
    var currentStreakDays: Int
    var daysLoggedThisWeek: Int
    var calorieTargetDays: Int
    var averageCalories: Double
    var averageProtein: Double
    var averageCarbs: Double
    var averageFat: Double
    var foodLogsThisWeek: Int
    var dailyStats: [DailyStatsSnapshot]

    static let empty = StatsSnapshot(
        currentStreakDays: 0,
        daysLoggedThisWeek: 0,
        calorieTargetDays: 0,
        averageCalories: 0,
        averageProtein: 0,
        averageCarbs: 0,
        averageFat: 0,
        foodLogsThisWeek: 0,
        dailyStats: []
    )
}

extension DailyStatsSnapshot {
    var hasFood: Bool { caloriesEaten > 0 }

    /// Within 15% of the day's calorie target. The bar's colour and the legend's
    /// counts both read this, so a day cannot be ochre in the chart and counted
    /// as in range underneath it.
    var isWithinCalorieRange: Bool {
        guard hasFood, let target = targetCalories, target > 0 else { return false }
        return abs(caloriesEaten - target) <= target * 0.15
    }
}

extension StatsSnapshot {
    /// How many days a week needs before its averages are worth printing —
    /// the `Week · day 2` artboard's line, and the divisor `StatsCalculator`
    /// averages over.
    static let minimumDaysForAverages = 4

    var daysWithFood: Int { dailyStats.filter(\.hasFood).count }

    /// `calorieTargetDays` counts the days that hit the range, and an empty day
    /// hits nothing, so the rest of the days with food are the ones that missed.
    var daysOutsideCalorieRange: Int { max(daysWithFood - calorieTargetDays, 0) }

    var hasEnoughDaysForAverages: Bool { daysWithFood >= Self.minimumDaysForAverages }
}
