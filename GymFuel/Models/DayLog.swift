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
    var trainingIntensity: TrainingIntensity?
    var sessionType: SessionType?
    var macroTargets: Macros
    var fuelScore: FuelScore?
    var consumedMacros: Macros?
    
    init(
        id: String,
        userId: String,
        date: Date,
        isTrainingDay: Bool = true,
        sessionStart: Date? = nil,
        trainingIntensity: TrainingIntensity? = .normal,
        sessionType: SessionType? = nil,
        macroTargets: Macros = .zero,
        fuelScore: FuelScore? = nil,
        consumedMacros: Macros? = .zero
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.isTrainingDay = isTrainingDay
        self.sessionStart = sessionStart
        self.trainingIntensity = trainingIntensity
        self.sessionType = sessionType
        self.macroTargets = macroTargets
        self.fuelScore = fuelScore
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
            bySettingHour: 18,
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
            trainingIntensity: .normal,
            sessionType: .strength, // adjust to one of your SessionType cases
            macroTargets: Macros(
                calories: 2400,
                protein: 160,
                carbs: 260,
                fat: 70
            ),
            fuelScore: FuelScore(total: 89, macroAdherence: 93, timingAdherence: 77)
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
            ),
            fuelScore: nil
        )
    }()
}



