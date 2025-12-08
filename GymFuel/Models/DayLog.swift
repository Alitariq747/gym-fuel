//
//  DayLog.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 07/12/2025.
//

import Foundation

struct DayLog {
    let id: String              // document ID, e.g. "2025-12-07"
    let dateString: String      // same as id for now
    
    var dayType: String         // "rest", "normal", "hard"
    
    var targetCalories: Double
    var targetProtein: Double
    var targetCarbs: Double
    var targetFat: Double
    
    var totalCalories: Double
    var totalProtein: Double
    var totalCarbs: Double
    var totalFat: Double
}
