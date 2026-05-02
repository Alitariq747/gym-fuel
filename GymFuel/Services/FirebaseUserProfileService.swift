//
//  FirebaseUserProfileService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import Foundation
import FirebaseFirestore

final class FirebaseUserProfileService: @unchecked Sendable {
    static let shared = FirebaseUserProfileService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    private func profileDocument(for uid: String) -> DocumentReference {
        return db.collection("users").document(uid)
    }
    
    private func decodeProfileDocument(from snapshot: DocumentSnapshot) throws -> UserProfile {
        let document = try snapshot.data(as: UserProfileDocument.self)
        return UserProfile(id: snapshot.documentID, document: document)
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
        
        if snapshot.exists {
            return try decodeProfileDocument(from: snapshot)
        } else {
            // create a default profile
            let defaultProfile = UserProfile(id: uid, name: "", heightCm: nil, age: nil, weightKg: nil, goalType: nil, nonTrainingActivityLevel: nil, isOnboardingComplete: false, gender: .preferNotToSay)
            
            var data = try Firestore.Encoder().encode(defaultProfile.document)
            data["createdAt"] = FieldValue.serverTimestamp()
            data["updatedAt"] = FieldValue.serverTimestamp()
            
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
    
    func updateProfile(for uid: String, name: String, heightCm: Double?, age: Int?, weightKg: Double?, goalType: GoalType?, nonTrainingActivityLevel: NonTrainingActivityLevel?, isOnboardingComplete: Bool, gender: Gender) async throws -> UserProfile {
        let docRef = profileDocument(for: uid)
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let profile = UserProfile(
            id: uid,
            name: trimmedName,
            heightCm: heightCm,
            age: age,
            weightKg: weightKg,
            goalType: goalType,
            nonTrainingActivityLevel: nonTrainingActivityLevel,
            isOnboardingComplete: isOnboardingComplete,
            gender: gender
        )
        var data = try Firestore.Encoder().encode(profile.document)
        data["updatedAt"] = FieldValue.serverTimestamp()
        
        try await withCheckedThrowingContinuation {( continuation: CheckedContinuation<Void,Error>) in
            docRef.setData(data, merge: true) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
            }
        }
        return profile
    }
    
  
        
}
