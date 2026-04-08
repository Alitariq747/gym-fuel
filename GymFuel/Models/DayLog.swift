//
//  DayLog.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 11/12/2025.
//

import Foundation

struct DayLog: Codable, Identifiable, Equatable {
    
    let id: String
    let userId: String // user id from firebase
    var date: Date
    var isTrainingDay: Bool
    var sessionStart: Date?
    var sessionDurationMinutes: Int?
    var trainingIntensity: TrainingIntensity?
    var sessionType: SessionType?
    var macroTargets: Macros
    var consumedMacros: Macros?
    
    init(
        id: String,
        userId: String,
        date: Date,
        isTrainingDay: Bool = true,
        sessionStart: Date? = nil,
        sessionDurationMinutes: Int? = nil,
        trainingIntensity: TrainingIntensity? = .normal,
        sessionType: SessionType? = nil,
        macroTargets: Macros = .zero,
        consumedMacros: Macros? = .zero
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.isTrainingDay = isTrainingDay
        self.sessionStart = sessionStart
        self.sessionDurationMinutes = sessionDurationMinutes
        self.trainingIntensity = trainingIntensity
        self.sessionType = sessionType
        self.macroTargets = macroTargets
        self.consumedMacros = consumedMacros
    }

 
}

extension DayLog {
    static let demoTrainingDay: DayLog = {
        let calendar = Calendar.current
        
        // Base date for the demo (today at midnight)
        let today = calendar.startOfDay(for: Date())
        
        // Session at 6:00 PM
        let sessionStart = calendar.date(
            bySettingHour: 5,
            minute: 0,
            second: 0,
            of: today
        )
        
        return DayLog(
            id: "demo-training-\(UUID().uuidString)",
            userId: "demo-user-id",
            date: today,
            isTrainingDay: true,
            sessionStart: sessionStart,
            sessionDurationMinutes: 75,
            trainingIntensity: .allOut,
            sessionType: .fullBody,
            macroTargets: Macros(
                calories: 2400,
                protein: 160,
                carbs: 260,
                fat: 70
            )
        )
    }()
    
    static let demoRestDay: DayLog = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return DayLog(
            id: "demo-rest-\(UUID().uuidString)",
            userId: "demo-user-id",
            date: today,
            isTrainingDay: false,
            sessionStart: nil,
            trainingIntensity: nil,
            sessionType: nil,
            macroTargets: Macros(
                calories: 2200,
                protein: 140,
                carbs: 230,
                fat: 65
            )
        )
    }()
}

