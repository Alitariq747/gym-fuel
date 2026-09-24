//
//  StatsCalculator.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2026.
//

import Foundation

struct StatsCalculator {
    func calculate(
        weeklyEntries: [LogEntry],
        currentStreakEntries: [LogEntry],
        targetMacros: Macros?,
        selectedWeekStart: Date,
        calendar: Calendar = .current
    ) -> StatsSnapshot {
        guard let selectedWeekEnd = calendar.date(byAdding: .day, value: 7, to: selectedWeekStart) else {
            return .empty
        }

        let weekEntries = weeklyEntries.filter { entry in
            entry.loggedAt >= selectedWeekStart && entry.loggedAt < selectedWeekEnd
        }
        let loggedDays = Set(weekEntries.map { calendar.startOfDay(for: $0.loggedAt) })
        let foodLogs = weekEntries.count
        let dailyStats = (0..<7).compactMap { dayOffset -> DailyStatsSnapshot? in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: selectedWeekStart) else {
                return nil
            }
            let dayEntries = weekEntries.filter { calendar.isDate($0.loggedAt, inSameDayAs: date) }
            let foodMacros = dayEntries.compactMap { $0.feedback?.macros }.reduce(.zero) { partial, macros in
                Macros(
                    calories: partial.calories + macros.calories,
                    protein: partial.protein + macros.protein,
                    carbs: partial.carbs + macros.carbs,
                    fat: partial.fat + macros.fat
                )
            }
            return DailyStatsSnapshot(
                date: date,
                caloriesEaten: foodMacros.calories,
                protein: foodMacros.protein,
                carbs: foodMacros.carbs,
                fat: foodMacros.fat,
                targetCalories: targetMacros?.calories,
                targetProtein: targetMacros?.protein,
                targetCarbs: targetMacros?.carbs,
                targetFat: targetMacros?.fat
            )
        }

        var snapshot = StatsSnapshot.empty
        snapshot.currentStreakDays = currentStreakDays(from: currentStreakEntries, calendar: calendar)
        snapshot.daysLoggedThisWeek = loggedDays.count
        snapshot.calorieTargetDays = dailyStats.filter(\.isWithinCalorieRange).count

        // Over the days with food, not over seven. A half-logged week divided by
        // seven reports an average nobody ate, and the Week card gates the figure
        // on `minimumDaysForAverages` precisely because the denominator is days
        // that happened.
        let averagedDays = Double(max(dailyStats.filter(\.hasFood).count, 1))
        snapshot.averageCalories = dailyStats.reduce(0) { $0 + $1.caloriesEaten } / averagedDays
        snapshot.averageProtein = dailyStats.reduce(0) { $0 + $1.protein } / averagedDays
        snapshot.averageCarbs = dailyStats.reduce(0) { $0 + $1.carbs } / averagedDays
        snapshot.averageFat = dailyStats.reduce(0) { $0 + $1.fat } / averagedDays
        snapshot.foodLogsThisWeek = foodLogs
        snapshot.dailyStats = dailyStats
        return snapshot
    }

    private func currentStreakDays(from entries: [LogEntry], calendar: Calendar) -> Int {
        let loggedDays = Set(entries.map { calendar.startOfDay(for: $0.loggedAt) })
        var day = calendar.startOfDay(for: .now)
        if !loggedDays.contains(day),
           let yesterday = calendar.date(byAdding: .day, value: -1, to: day) {
            day = yesterday
        }

        var count = 0
        while loggedDays.contains(day) {
            count += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }
        return count
    }
}
