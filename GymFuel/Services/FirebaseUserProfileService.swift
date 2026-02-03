//
//  FirebaseUserProfileService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import Foundation
import FirebaseFirestore

final class FirebaseUserProfileService {
    static let shared = FirebaseUserProfileService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    private func profileDocument(for uid: String) -> DocumentReference {
        return db.collection("users").document(uid)
    }
    
    private func mapDocument(id: String, data: [String : Any]) -> UserProfile {
        let name = data["name"] as? String ?? ""
        let isOnboardingComplete = data["isOnboardingComplete"] as? Bool ?? false
        let gender = data["gender"] as? String ?? ""
        let heightCm = data["heightCm"] as? Double
        let age = data["age"] as? Int
        let weightKg = data["weightKg"] as? Double
        
        let trainingGoalString = data["trainingGoal"] as? String
        let trainingGoal = trainingGoalString.flatMap { TrainingGoal(rawValue: $0) }
        
        let trainingDaysPerWeek = data["trainingDaysPerWeek"] as? Int
        
        let trainingExperienceString = data["trainingExperience"] as? String
        let trainingExperience = trainingExperienceString.flatMap { TrainingExperience(rawValue: $0) }
        
        let trainingStyleString = data["trainingStyle"] as? String
        let trainingStyle = trainingStyleString.flatMap { TrainingStyle(rawValue: $0) }
        
        let trainingTimeString = data["trainingTimeOfDay"] as? String
        let trainingTimeOfDay = trainingTimeString.flatMap { TrainingTimeOfDay(rawValue: $0) }
        
        let activityString = data["nonTrainingActivityLevel"] as? String
        let nonTrainingActivityLevel = activityString.flatMap { NonTrainingActivityLevel(rawValue: $0) } 
        
        return UserProfile(id: id, name: name, heightCm: heightCm ,age: age, weightKg: weightKg, trainingGoal: trainingGoal, trainingDaysPerWeek: trainingDaysPerWeek, trainingExperience: trainingExperience, trainingStyle: trainingStyle, trainingTimeOfDay: trainingTimeOfDay, nonTrainingActivityLevel: nonTrainingActivityLevel, isOnboardingComplete: isOnboardingComplete, gender: gender)
    }
    
    func fetchProfile(for uid: String) async throws -> UserProfile {
           let docRef = profileDocument(for: uid)
           
           // Wrap Firestore's callback-based API in async/await
        let snapshot: DocumentSnapshot = try await withCheckedThrowingContinuation { continuation in
               docRef.getDocument { snapshot, error in
                   if let error = error {
                       continuation.resume(throwing: error)
                   } else if let snapshot = snapshot {
                       continuation.resume(returning: snapshot)
                   } else {
                       let err = NSError(
                           domain: "Firestore",
                           code: 0,
                           userInfo: [NSLocalizedDescriptionKey: "No snapshot returned"]
                       )
                       continuation.resume(throwing: err)
                   }
               }
           }
        
        if snapshot.exists, let data = snapshot.data() {
            return mapDocument(id: snapshot.documentID, data: data)
        } else {
            // create a default profile
            let defaultProfile = UserProfile(id: uid, name: "", heightCm: nil , age: nil, weightKg: nil, trainingGoal: nil, trainingDaysPerWeek: nil , trainingExperience: nil, trainingStyle: nil, trainingTimeOfDay: nil, nonTrainingActivityLevel: nil, isOnboardingComplete: false, gender: "")
            
            let data: [String: Any] = [
                "name": "",
                "isOnboardingComplete": false,
                "gender": "",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            // put this data to Firestore
            try await withCheckedThrowingContinuation {(continuation: CheckedContinuation<Void, Error>) in
                docRef.setData(data) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
            return defaultProfile
        }
           
          
       }
    
    func updateProfile(for uid: String, name: String, heightCm: Double? , age: Int?, weightKg: Double?, trainingGoal: TrainingGoal?, trainingDaysPerWeek: Int?, trainingExperience: TrainingExperience?, trainingStyle: TrainingStyle?, trainingTimeOfDay: TrainingTimeOfDay?, nonTrainingActivityLevel: NonTrainingActivityLevel?, isOnboardingComplete: Bool, gender: String) async throws -> UserProfile {
        let docRef = profileDocument(for: uid)
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGender = gender.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var data: [String: Any] = [
            "name": trimmedName,
            "gender": trimmedGender,
            "isOnboardingComplete": isOnboardingComplete,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let heightCm {
            data["heightCm"] = heightCm
        }
        
        if let age {
            data["age"] = age
        }
        
        if let weightKg {
            data["weightKg"] = weightKg
        }
        
        if let trainingGoal {
                data["trainingGoal"] = trainingGoal.rawValue
            }
        if let trainingDaysPerWeek {
            data["trainingDaysPerWeek"] = trainingDaysPerWeek
        }
        
        if let trainingExperience {
            data["trainingExperience"] = trainingExperience.rawValue
            }
        
        if let trainingStyle {
            data["trainingStyle"] = trainingStyle.rawValue
        }
        
        if let trainingTimeOfDay {
            data["trainingTimeOfDay"] = trainingTimeOfDay.rawValue
        }
        
        if let nonTrainingActivityLevel {
            data["nonTrainingActivityLevel"] = nonTrainingActivityLevel.rawValue
        }
        
        try await withCheckedThrowingContinuation {( continuation: CheckedContinuation<Void,Error>) in
            docRef.setData(data, merge: true) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
            }
        }
        return UserProfile(id: uid, name: trimmedName, heightCm: heightCm, age: age , weightKg: weightKg, trainingGoal: trainingGoal, trainingDaysPerWeek: trainingDaysPerWeek, trainingExperience: trainingExperience, trainingStyle: trainingStyle, trainingTimeOfDay: trainingTimeOfDay, nonTrainingActivityLevel: nonTrainingActivityLevel, isOnboardingComplete: isOnboardingComplete, gender: trimmedGender)
    }
    
  
        
}

