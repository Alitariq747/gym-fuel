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
    case push
    case pull
    case legs
    case upper
    case lower
    case fullBody
    case conditioning
    case cardio
    case mobility
    case sports
    
    var displayName: String {
          switch self {
          case .push: return "Push Day"
          case .pull: return "Pull Day"
          case .legs: return "Leg Day"
          case .upper: return "Upper Body"
          case .lower: return "Lower Body"
          case .fullBody: return "Full Body"
          case .conditioning: return "Conditioning"
          case .cardio: return "Cardio"
          case .mobility: return "Mobility"
          case .sports: return "Sports"
          }
      }
}
