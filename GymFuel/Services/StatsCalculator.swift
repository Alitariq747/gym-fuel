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
        let foodLogs = weekEntries.filter { $0.type == .food }.count
        let workoutLogs = weekEntries.filter { $0.type == .exercise }.count
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
            let caloriesBurned = dayEntries.reduce(0) { $0 + ($1.feedback?.estimatedCalories ?? 0) }
            return DailyStatsSnapshot(
                date: date,
                caloriesEaten: foodMacros.calories,
                caloriesBurned: caloriesBurned,
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
        snapshot.calorieTargetDays = dailyStats.filter { day in
            guard let target = day.targetCalories, target > 0 else { return false }
            return abs(day.caloriesEaten - target) <= target * 0.15
        }.count
        snapshot.proteinTargetDays = dailyStats.filter { day in
            guard let target = day.targetProtein, target > 0 else { return false }
            return day.protein >= target * 0.9
        }.count
        snapshot.averageCalories = dailyStats.reduce(0) { $0 + $1.caloriesEaten } / Double(dailyStats.count)
        snapshot.averageProtein = dailyStats.reduce(0) { $0 + $1.protein } / Double(dailyStats.count)
        snapshot.averageCarbs = dailyStats.reduce(0) { $0 + $1.carbs } / Double(dailyStats.count)
        snapshot.averageFat = dailyStats.reduce(0) { $0 + $1.fat } / Double(dailyStats.count)
        snapshot.foodLogsThisWeek = foodLogs
        snapshot.workoutLogsThisWeek = workoutLogs
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
