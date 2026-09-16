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
    
    private func decodeProfile(from snapshot: DocumentSnapshot) throws -> UserProfile {
        var profile = try snapshot.data(as: UserProfile.self)
        profile.id = snapshot.documentID
        return profile
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
            return try decodeProfile(from: snapshot)
        } else {
            // create a default profile
            let defaultProfile = UserProfile(id: uid, name: "", heightCm: nil, age: nil, weightKg: nil, goalType: nil, activityLevel: nil, isOnboardingComplete: false, gender: .preferNotToSay)

            var data = try Firestore.Encoder().encode(defaultProfile)
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
    
    /// Writes only `weightKg`, for the weigh-in path.
    ///
    /// Deliberately not `updateProfile(_:)`: that re-encodes the whole document
    /// from possibly-stale memory and would clobber a concurrent edit. A partial
    /// write is safe here because the rules' `hasOnly()` accepts subsets and both
    /// keys are already in the allowed list.
    ///
    /// - Important: the completion fires only on **server acknowledgement**, so
    ///   awaiting this offline never resumes. Callers must branch on
    ///   `NetworkMonitor` and use `updateWeightLocally` instead.
    func updateWeight(_ weightKg: Double, for uid: String) async throws {
        let docRef = profileDocument(for: uid)
        let data: [String: Any] = [
            "weightKg": weightKg,
            "updatedAt": FieldValue.serverTimestamp(),
        ]

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            docRef.setData(data, merge: true) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// Queues the same write into Firestore's local cache without awaiting the
    /// server, so an offline weigh-in lands immediately and syncs later.
    func updateWeightLocally(_ weightKg: Double, for uid: String) {
        let data: [String: Any] = [
            "weightKg": weightKg,
            "updatedAt": FieldValue.serverTimestamp(),
        ]
        profileDocument(for: uid).setData(data, merge: true)
    }

    func updateProfile(_ profile: UserProfile) async throws -> UserProfile {
        let docRef = profileDocument(for: profile.id)

        var normalized = profile
        normalized.normalize()

        var data = try Firestore.Encoder().encode(normalized)
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
        return normalized
    }
    
  
        
}
