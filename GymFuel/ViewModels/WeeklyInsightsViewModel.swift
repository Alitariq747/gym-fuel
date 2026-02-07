//
//  WeeklyInsightsViewModel.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 19/01/2026.
//

import Foundation
import Combine

struct DayFuelRow: Identifiable {
    let date: Date
    let fuelScore: Int?
    let isTrainingDay: Bool
    let intensity: TrainingIntensity?
    let sessionType: SessionType?
    let hasLog: Bool
    
    var id: Date { date }
}

struct DailyFuelScorePoint: Identifiable {
    let date: Date
    let score: Int?
    var id: Date { date }
}

struct MacroPercentages {
    let caloriesPct: Double
    let proteinPct: Double
    let carbsPct: Double
    let fatPct: Double
}

@MainActor
final class WeeklyInsightsViewModel: ObservableObject {
    
    @Published var selectedWeekStart: Date
    @Published private(set) var weekDayLogs: [Date: DayLog] = [:]
    
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
  
    // Dependencies
    private let profile: UserProfile
    private let dayLogService: DayLogService
    private let calendar = Calendar.current
    private let utcCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return cal
    }()
    
    init(profile: UserProfile, initialDate: Date = Date(), dayLogService: DayLogService = FirebaseDayLogService()) {
        self.profile = profile
        self.dayLogService = dayLogService
        
        if let weekStart = calendar.dateInterval(of: .weekOfYear, for: initialDate)?.start {
            self.selectedWeekStart = weekStart
        } else {
            self.selectedWeekStart = calendar.startOfDay(for: initialDate)
        }
    }
    
    var weekDates: [Date] {
        let start = calendar.startOfDay(for: selectedWeekStart)
        return(0..<7).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: start)
        }
    }
    func updateWeekStart(to newWeekStart: Date) {
     
        let normalizedWeekStart: Date
        if let weekStart = calendar.dateInterval(of: .weekOfYear, for: newWeekStart)?.start {
            normalizedWeekStart = weekStart
        } else {
            normalizedWeekStart = calendar.startOfDay(for: newWeekStart)
        }
        
      
        guard normalizedWeekStart != selectedWeekStart else { return }
        selectedWeekStart = normalizedWeekStart
      
        
    }

    
    func loadWeek(for weekStart: Date) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let weekDatesSnapshot = weekDates(for: weekStart)
        
        guard let firstDay = weekDatesSnapshot.first,
              let lastDay = weekDatesSnapshot.last else {
            return
        }
        
        // Query using UTC day boundaries for consistency with storage.
        let startOfRange = utcCalendar.startOfDay(for: firstDay)
        guard let endOfRange = utcCalendar.date(byAdding: .day, value: 1, to: utcCalendar.startOfDay(for: lastDay)) else {
            errorMessage = "Failed to compute week range."
            return
        }
        
        let userId = profile.id
        
        do {
            let logs = try await dayLogService.fetchDayLogs(for: userId, from: startOfRange, to: endOfRange)
            
            if Task.isCancelled { return }

            
            var byDate: [Date: DayLog] = [:]
            for log in logs {
                let dayStart = calendar.startOfDay(for: log.date)
                byDate[dayStart] = log
            }
            
            self.weekDayLogs = byDate
        } catch {
            
            if Task.isCancelled { return }

            self.errorMessage = error.localizedDescription
        }
    }
    
    var trainingDaysPlanned: Int {
        if let days = profile.trainingDaysPerWeek {
            return max(0, min(7, days))
        }
        return weekDayLogs.values.filter { $0.isTrainingDay }.count
    }
    
    var trainingDaysLogged: Int {
        weekDayLogs.values.filter { log in
            guard log.isTrainingDay else { return false }
            let total = log.fuelScore?.total ?? 0
            return total > 0
        }.count
    }
    
    var restDays: Int {
        max(0, 7 - trainingDaysPlanned)
    }
    
    var averageFuelScore: Int? {
        let scores: [Int] = weekDayLogs.values.compactMap { log in
                let total = log.fuelScore?.total ?? 0
            return total > 0 ? total : nil
        }
        guard !scores.isEmpty else { return nil }
        
        let sum = scores.reduce(0, +)
        return sum / scores.count
    }
    
    var highScoreDays: Int {
        weekDayLogs.values.filter { log in
            let total = log.fuelScore?.total ?? 0
            return total >= 75
        }.count
    }
    
    var dayRows: [DayFuelRow] {
        weekDates.map { date in
            let dayStart = calendar.startOfDay(for: date)
            let log = weekDayLogs[dayStart]
            
            let totalScore = log?.fuelScore?.total ?? 0
            let displayScore = totalScore > 0 ? totalScore : nil
            
            return DayFuelRow(
                date: dayStart,
                fuelScore: displayScore,
                isTrainingDay: log?.isTrainingDay ?? false,
                intensity: log?.trainingIntensity,
                sessionType: log?.sessionType,
                hasLog: log != nil
            )
        }
    }
    
    var dailyFuelScores: [DailyFuelScorePoint] {
        weekDates.map { date in
            let dayStart = calendar.startOfDay(for: date)
            let rawScore = weekDayLogs[dayStart]?.fuelScore?.total
            let score = (rawScore ?? 0) > 0 ? rawScore : nil
            
            return DailyFuelScorePoint(date: dayStart, score: score)
        }
    }

    private func weekDates(for weekStart: Date) -> [Date] {
        let start = calendar.startOfDay(for: weekStart)
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
    }
    
    // helper to compute percentages
    private func macroPercentages(for dayLog: DayLog) -> MacroPercentages? {
        guard let consumedMacros = dayLog.consumedMacros else { return nil }
        
        let targets = dayLog.macroTargets
        
        func pct(actual: Double, target: Double) -> Double? {
            guard target > 0 else { return nil }
            return (actual / target) * 100
        }
        
        guard
            let caloriesPct = pct(actual: consumedMacros.calories, target: targets.calories),
            let proteinPct = pct(actual: consumedMacros.protein, target: targets.protein),
            let carbsPct = pct(actual: consumedMacros.carbs, target: targets.carbs),
            let fatPct = pct(actual: consumedMacros.fat, target: targets.fat)
        else { return nil }
        
        return MacroPercentages(caloriesPct: caloriesPct, proteinPct: proteinPct, carbsPct: carbsPct, fatPct: fatPct)
    }
    
    // for every date we have % of macros consumed per macro
    var weeklyMacroPercentages: [(date: Date, macros: MacroPercentages)] {
        weekDates.compactMap { date in
            let dayStart = calendar.startOfDay(for: date)
            guard let log = weekDayLogs[dayStart],
                  let percentages = macroPercentages(for: log)
            else { return nil }
          
            return (date: dayStart, macros: percentages)
        }
    }
    
    var weeklyMacroOverview: MacroPercentages? {
        let entries = weeklyMacroPercentages
        guard !entries.isEmpty else { return nil }
        
        let count = Double(entries.count)
        
        let totalCalories = entries.reduce(0.0) { $0 + $1.macros.caloriesPct }
        let totalProtein = entries.reduce(0.0) { $0 + $1.macros.proteinPct }
        let totalCarbs = entries.reduce(0.0) { $0 + $1.macros.carbsPct }
        let totalFat = entries.reduce(0.0) { $0 + $1.macros.fatPct }
        
        return MacroPercentages(
            caloriesPct: totalCalories / count,
            proteinPct: totalProtein / count,
            carbsPct: totalCarbs / count,
            fatPct: totalFat / count
        )
    }
    
}
