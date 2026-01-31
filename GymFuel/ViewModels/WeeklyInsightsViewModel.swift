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
        
      
        selectedWeekStart = normalizedWeekStart
        
      
        Task {
            await loadCurrentWeek()
        }
    }

    
    func loadCurrentWeek() async {
        isLoading = true
        errorMessage = nil
        
        guard let firstDay = weekDates.first,
              let lastDay = weekDates.last else {
            isLoading = false
            return
        }
        
        let startOfRange = calendar.startOfDay(for: firstDay)
        guard let endOfRange = calendar.date(byAdding: .day, value: 1 ,to: calendar.startOfDay(for: lastDay)) else {
            isLoading = false
            errorMessage = "Failed to compute week range."
            return
        }
        
        let userId = profile.id
        
        do {
            let logs = try await dayLogService.fetchDayLogs(for: userId, from: startOfRange, to: endOfRange)
            
            var byDate: [Date: DayLog] = [:]
            for log in logs {
                let dayStart = calendar.startOfDay(for: log.date)
                byDate[dayStart] = log
            }
            
            self.weekDayLogs = byDate
        } catch {
            self.errorMessage = error.localizedDescription
            self.weekDayLogs = [:]
        }
        isLoading = false
    }
    
    var trainingDaysPlanned: Int {
        weekDayLogs.values.filter { $0.isTrainingDay }.count
    }
    
    var trainingDaysLogged: Int {
        weekDayLogs.values.filter { log in
            guard log.isTrainingDay else { return false }
            let total = log.fuelScore?.total ?? 0
            return total > 0
        }.count
    }
    
    var restDays: Int {
        weekDayLogs.values.filter { !$0.isTrainingDay }.count
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
            
            return DayFuelRow(date: dayStart, fuelScore: displayScore, isTrainingDay: log?.isTrainingDay ?? false, intensity: log?.trainingIntensity, sessionType: log?.sessionType)
        }
    }
    
    var dailyFuelScores: [DailyFuelScorePoint] {
        weekDates.map { date in
            let dayStart = calendar.startOfDay(for: date)
            let score = weekDayLogs[dayStart]?.fuelScore?.total ?? 0
            
            return DailyFuelScorePoint(date: dayStart, score: score)
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
