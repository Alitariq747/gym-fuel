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

    /// Every key the plan and the saved targets own. `weightKg` is deliberately
    /// absent: weigh-ins write it, and nothing on the targets screen may.
    private static let planAndTargetKeys = [
        "goalType",
        "activityLevel",
        "goalWeightKg",
        "planStartedOn",
        "planStartWeightKg",
        "targetCalories",
        "targetProteinG",
        "targetCarbsG",
        "targetFatG",
        "maintenanceCalories",
        "targetsSetOn",
        "targetsSetAtWeightKg",
    ]

    /// Writes the plan and the saved targets, and nothing else.
    ///
    /// Deliberately not `updateProfile(_:)`, for the reason given on
    /// `updateWeight`: re-encoding the whole document from possibly-stale memory
    /// would put a concurrently-edited field back the way it was. The rules'
    /// `hasOnly()` accepts subsets and every key here is already allowed.
    ///
    /// - Important: as with every write here, the completion fires only on
    ///   **server acknowledgement**, so awaiting this offline does not resume.
    func updateTargets(for profile: UserProfile) async throws {
        let data = try planAndTargetData(for: profile)
        let docRef = profileDocument(for: profile.id)

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
    /// server, so an offline change to the targets lands immediately and syncs
    /// later. Same reason as `updateWeightLocally`.
    func updateTargetsLocally(for profile: UserProfile) throws {
        let data = try planAndTargetData(for: profile)
        profileDocument(for: profile.id).setData(data, merge: true)
    }

    /// The write itself, built once for both paths.
    private func planAndTargetData(for profile: UserProfile) throws -> [String: Any] {
        let encoded = try Firestore.Encoder().encode(profile)

        var data: [String: Any] = ["updatedAt": FieldValue.serverTimestamp()]
        for key in Self.planAndTargetKeys {
            // Encoding leaves a nil field out entirely, and `merge: true` would
            // then keep whatever is stored — so a goal weight dropped by
            // switching to Maintain has to be removed, not omitted.
            data[key] = encoded[key] ?? FieldValue.delete()
        }
        return data
    }

    func updateProfile(_ profile: UserProfile) async throws -> UserProfile {
        let write = try profileWrite(for: profile)
        let docRef = profileDocument(for: profile.id)

        try await withCheckedThrowingContinuation {( continuation: CheckedContinuation<Void,Error>) in
            docRef.setData(write.data, merge: true) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
            }
        }
        return write.normalized
    }

    /// Queues the whole document into Firestore's local cache without awaiting the
    /// server, so an offline profile edit lands immediately and syncs later.
    func updateProfileLocally(_ profile: UserProfile) throws -> UserProfile {
        let write = try profileWrite(for: profile)
        profileDocument(for: profile.id).setData(write.data, merge: true)
        return write.normalized
    }

    /// Normalizes and encodes a whole profile, so the awaited and local paths write
    /// exactly the same thing.
    private func profileWrite(for profile: UserProfile) throws -> (normalized: UserProfile, data: [String: Any]) {
        var normalized = profile
        normalized.normalize()

        var data = try Firestore.Encoder().encode(normalized)
        data["updatedAt"] = FieldValue.serverTimestamp()

        return (normalized, data)
    }
    
  
        
}
