//
//  TrainingIntensity&SessionType.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 11/12/2025.
//

import Foundation

enum TrainingIntensity: String, CaseIterable, Codable {
    case recovery
    case normal
    case hard
    case allOut
}

enum SessionType: String, CaseIterable, Codable {
    case strength
    case hypertrophy
    case mixed
    case endurance
}
