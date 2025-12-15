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
    
    var displayName: String {
        switch self {
        case .recovery:
            return "Recovery"
        case .normal:
            return "Normal"
        case .hard:
            return "Hard"
        case .allOut:
            return "All Out"
        
        }
    }
}

enum SessionType: String, CaseIterable, Codable {
    case strength
    case hypertrophy
    case mixed
    case endurance
    
    var displayName: String {
          switch self {
          case .strength: return "Strength"
          case .hypertrophy: return "Hypertrophy"
          case .mixed: return "CrossFit"
          case .endurance: return "Endurance"
          }
      }
}
