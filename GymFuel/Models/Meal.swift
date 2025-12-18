//
//  Meals.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 11/12/2025.
//

import Foundation

struct Meal: Identifiable, Codable, Equatable {
    let id: String // firebase doc id
    let userId: String // firebase userID
    let dayLogId: String // id of DayLog this meal belongs to
    
    var loggedAt: Date
    var description: String
    var macros: Macros
    var aiName: String? = nil
    var aiConfidence: Double? = nil
    var aiWarnings: [String] = []
    var aiNotes: String? = nil
    var aiAssumptions: [String] = []

    
}

extension Meal {
   
    func timingTag(
        relativeTo sessionStart: Date?,
        isTrainingDay: Bool,
        preWindowHours: Double = 3.0,
        postWindowHours: Double = 4.0
    ) -> MealTimingTag {
        // If it's a rest day, all meals are "restDay".
        guard isTrainingDay, let sessionStart = sessionStart else {
            return .restDay
        }
        
        let diffInSeconds = loggedAt.timeIntervalSince(sessionStart)
        let diffInHours = diffInSeconds / 3600.0
        
        if diffInHours >= -preWindowHours && diffInHours < 0 {
            return .preWorkout
        } else if diffInHours >= 0 && diffInHours <= postWindowHours {
            return .postWorkout
        } else {
            return .otherOnTrainingDay
        }
    }
}

extension Meal {
    static func demoMeals(forTrainingDay dayLog: DayLog) -> [Meal] {
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: dayLog.date)
        let userId = dayLog.userId
        let dayLogId = dayLog.id
        
        func at(_ hour: Int, _ minute: Int) -> Date {
            calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: baseDate
            ) ?? baseDate
        }
        
        return [
            // ~09:00 → far from session → .otherOnTrainingDay
            Meal(
                id: "m-breakfast",
                userId: userId,
                dayLogId: dayLogId,
                loggedAt: at(9, 0),
                description: "Greek yogurt with berries and oats",
                macros: Macros(
                    calories: 450,
                    protein: 30,
                    carbs: 55,
                    fat: 12
                )
            ),
            
            // 16:30 → within 3h before 18:00 → .preWorkout
            Meal(
                id: "m-pre-snack",
                userId: userId,
                dayLogId: dayLogId,
                loggedAt: at(16, 30),
                description: "Rice cake with peanut butter",
                macros: Macros(
                    calories: 250,
                    protein: 10,
                    carbs: 30,
                    fat: 10
                )
            ),
            
            // 17:30 → still pre-workout
            Meal(
                id: "m-pre-snack-2",
                userId: userId,
                dayLogId: dayLogId,
                loggedAt: at(17, 30),
                description: "Banana",
                macros: Macros(
                    calories: 100,
                    protein: 1,
                    carbs: 25,
                    fat: 0
                )
            ),
            
            // 18:30 → within 4h after 18:00 → .postWorkout
            Meal(
                id: "m-post-shake",
                userId: userId,
                dayLogId: dayLogId,
                loggedAt: at(18, 30),
                description: "Whey shake with banana",
                macros: Macros(
                    calories: 250,
                    protein: 30,
                    carbs: 25,
                    fat: 5
                )
            ),
            
            // 21:00 → still within 4h after 18:00 → .postWorkout
            Meal(
                id: "m-dinner",
                userId: userId,
                dayLogId: dayLogId,
                loggedAt: at(21, 0),
                description: "Chicken, rice and veggies",
                macros: Macros(
                    calories: 650,
                    protein: 45,
                    carbs: 75,
                    fat: 15
                )
            ),
            
            // 23:30 → >4h after → .otherOnTrainingDay
            Meal(
                id: "m-late-snack",
                userId: userId,
                dayLogId: dayLogId,
                loggedAt: at(23, 30),
                description: "Cottage cheese",
                macros: Macros(
                    calories: 200,
                    protein: 20,
                    carbs: 8,
                    fat: 9
                )
            )
        ]
    }
    
    static func demoMeals(forRestDay dayLog: DayLog) -> [Meal] {
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: dayLog.date)
        let userId = dayLog.userId
        let dayLogId = dayLog.id
        
        func at(_ hour: Int, _ minute: Int) -> Date {
            calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: baseDate
            ) ?? baseDate
        }
        
        return [
            Meal(
                id: "r-breakfast",
                userId: userId,
                dayLogId: dayLogId,
                loggedAt: at(9, 30),
                description: "Omelette and toast",
                macros: Macros(
                    calories: 400,
                    protein: 25,
                    carbs: 35,
                    fat: 15
                )
            ),
            Meal(
                id: "r-lunch",
                userId: userId,
                dayLogId: dayLogId,
                loggedAt: at(13, 0),
                description: "Beef bowl with rice",
                macros: Macros(
                    calories: 700,
                    protein: 40,
                    carbs: 70,
                    fat: 25
                )
            ),
            Meal(
                id: "r-dinner",
                userId: userId,
                dayLogId: dayLogId,
                loggedAt: at(20, 0),
                description: "Salmon with potatoes",
                macros: Macros(
                    calories: 650,
                    protein: 35,
                    carbs: 40,
                    fat: 30
                )
            )
        ]
    }
}
