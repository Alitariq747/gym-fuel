//
//  FirestoreUserService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import Foundation
import FirebaseFirestore

final class FirestoreUserService {
    static let shared = FirestoreUserService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    private var usersCollection: CollectionReference {
        db.collection("users")
    }
    
    func createDefaultUser(uid: String, email: String, completion: @escaping(Result<UserProfile, Error>) -> Void) {
        let docRef = usersCollection.document(uid)
        
        let data: [String: Any] = [
                        "uid": uid,
                        "email": email,
                        "goal": "recomp",
                        "heightCm": NSNull(),
                        "name": "",
                        "weightKg": NSNull(),
                        "createdAt": FieldValue.serverTimestamp()
            ]
        docRef.setData(data) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let profile = UserProfile(uid: uid, email: email, goal: "recomp", name: "", heightCm: nil, weightKg: nil)
                    completion(.success(profile))
                }
        }
    }
    
    func fetchProfile(uid: String, completion: @escaping(Result<UserProfile?, Error>) -> Void) {
        let docRef = usersCollection.document(uid)
        
        docRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
                completion(.success(nil))
                return
            }
            
            let email = data["email"] as? String ?? ""
            let goal = data["goal"] as? String ?? "recomp"
            let name = data["name"] as? String ?? ""
            let heightCm = data["heightCm"] as? Double
            let weightKg = data["weightKg"] as? Double
            
            let profile = UserProfile(
                       uid: uid,
                       email: email,
                       goal: goal,
                       name: name,
                       heightCm: heightCm,
                       weightKg: weightKg
                   )
                   completion(.success(profile))
            
        }
    }
}
