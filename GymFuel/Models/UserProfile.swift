//
//  UserProfile.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import Foundation

enum Gender: String, CaseIterable, Codable, Equatable {
    case male = "male"
    case female = "female"
    case preferNotToSay = "prefer_not_to_say"

    var displayName: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        case .preferNotToSay:
            return "Prefer not to say"
        }
    }

    var symbol: String {
        switch self {
        case .male:
            return "♂"
        case .female:
            return "♀"
        case .preferNotToSay:
            return "–"
        }
    }
}

struct UserProfile: Identifiable, Equatable {
    let id: String         
    var name: String
    var heightCm: Double?   
    var age: Int?
    var weightKg: Double?
    var goalType: GoalType?
    var nonTrainingActivityLevel: NonTrainingActivityLevel?
    var isOnboardingComplete: Bool
    var gender: Gender
}

let dummyProfile = UserProfile(id: "1111", name: "Ali", heightCm: 175, age: 38, weightKg: 83, goalType: .leanBulk, nonTrainingActivityLevel: .mostlySitting, isOnboardingComplete: true, gender: .male)

struct UserProfileDraft: Equatable {
    let id: String
    var name: String
    var heightCm: Double?
    var age: Int?
    var weightKg: Double?
    var goalType: GoalType?
    var nonTrainingActivityLevel: NonTrainingActivityLevel?
    var isOnboardingComplete: Bool
    var gender: Gender
    
    init(from profile: UserProfile) {
        self.id = profile.id
        self.name = profile.name
        self.gender = profile.gender
        self.heightCm = profile.heightCm
        self.age = profile.age
        self.weightKg = profile.weightKg
        self.goalType = profile.goalType
        self.nonTrainingActivityLevel = profile.nonTrainingActivityLevel
        self.isOnboardingComplete = profile.isOnboardingComplete
    }
    
    mutating func normalize() {
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func applying(to profile: UserProfile) -> UserProfile {
        UserProfile(
            id: profile.id,
            name: name,
            heightCm: heightCm,
            age: age,
            weightKg: weightKg,
            goalType: goalType,
            nonTrainingActivityLevel: nonTrainingActivityLevel,
            isOnboardingComplete: isOnboardingComplete,
            gender: gender
        )
    }
}

#if DEBUG
extension UserProfileDraft {
    static var preview: UserProfileDraft {
        var d = UserProfileDraft(from: dummyProfile)

        d.name = "Ahmad (Preview) "

        return d
    }
}
#endif
