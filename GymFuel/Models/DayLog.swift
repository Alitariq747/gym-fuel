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
    
    init(
        id: String,
        userId: String,
        date: Date,
        isTrainingDay: Bool = true,
        sessionStart: Date? = nil,
        trainingIntensity: TrainingIntensity? = .normal,
        sessionType: SessionType? = nil,
        macroTargets: Macros = .zero,
        fuelScore: FuelScore? = nil
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
    }

 
}



