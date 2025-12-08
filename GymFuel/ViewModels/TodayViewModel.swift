//
//  TodayViewModel.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 07/12/2025.
//

import Foundation

final class TodayViewModel: ObservableObject {
    
    @Published var dayLog: DayLog?
    @Published var meals: [Meal] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func loadToday() {
        
        isLoading = true
        errorMessage = nil
        
        FirebaseDayLogService.shared.loadOrCreateToday { [weak self] result in
            
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                    
                case .success(let log):
                    self.dayLog = log
                    self.loadMeals(for: log)
                case .failure(let error):
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.dayLog = nil
                    self.meals = []
                }
            }
        }
    }
    
    func setDayType(_ newType: String) {
        
        guard let currentDayLog = dayLog else { return }
        
        if currentDayLog.dayType == newType {
            return
        }
        
        FirebaseDayLogService.shared.updateDayType(for: currentDayLog, to: newType) { [weak self] result in
            
            guard let self = self else { return }
            
            self.isLoading = false
            
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedLog):
                    self.dayLog = updatedLog
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loadMeals(for log: DayLog) {
        FirebaseMealService.shared.fetchMeals(for: log) { [weak self] result in
        
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let meals):
                    self.meals = meals
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.meals = []
                }
            }
        }
    }
    
    func addMeal(description: String, calories: Double, protein: Double, carbs: Double, fat: Double) {
        guard let currentLog = dayLog else { return }
        
        self.isLoading = true
        self.errorMessage = nil
        
        FirebaseMealService.shared.addManualMeal(for: currentLog, description: description, calories: calories, protein: protein, carbs: carbs, fat: fat) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let (meal, updatedLog)):
                    self.dayLog = updatedLog
                    self.meals.append(meal)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }

            }
            
            
        }
    }
}
