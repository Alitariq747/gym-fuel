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
    
}

extension Meal {
   
    func timingTag(
        relativeTo sessionStart: Date?,
        isTrainingDay: Bool,
        preWindowHours: Double = 3.0,
        postWindowHours: Double = 2.0
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
