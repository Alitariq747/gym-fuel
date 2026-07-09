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
    var caloriesBurned: Double
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
    var proteinTargetDays: Int
    var averageCalories: Double
    var averageProtein: Double
    var averageCarbs: Double
    var averageFat: Double
    var foodLogsThisWeek: Int
    var workoutLogsThisWeek: Int
    var dailyStats: [DailyStatsSnapshot]

    static let empty = StatsSnapshot(
        currentStreakDays: 0,
        daysLoggedThisWeek: 0,
        calorieTargetDays: 0,
        proteinTargetDays: 0,
        averageCalories: 0,
        averageProtein: 0,
        averageCarbs: 0,
        averageFat: 0,
        foodLogsThisWeek: 0,
        workoutLogsThisWeek: 0,
        dailyStats: []
    )
}
