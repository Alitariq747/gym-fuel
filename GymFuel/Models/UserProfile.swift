//
//  UserProfile.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import Foundation


struct UserProfile: Identifiable, Equatable {
    let id: String         
    var name: String
    var heightCm: Double?   
    var age: Int?
    var weightKg: Double?
    var trainingGoal: TrainingGoal?
    var trainingDaysPerWeek: Int?    
    var trainingExperience: TrainingExperience?
    var trainingStyle: TrainingStyle?
    var trainingTimeOfDay: TrainingTimeOfDay?
    var nonTrainingActivityLevel: NonTrainingActivityLevel?
    var isOnboardingComplete: Bool
    var gender: String
}

var dummyProfile = UserProfile(id: "1111", name: "Ali", heightCm: 175, age: 38, weightKg: 83, trainingGoal: .muscleGain, trainingDaysPerWeek: 0, trainingExperience: .intermediate, trainingStyle: .hypertrophy,  trainingTimeOfDay: .morning, nonTrainingActivityLevel: .mostlySitting, isOnboardingComplete: true, gender: "male")
