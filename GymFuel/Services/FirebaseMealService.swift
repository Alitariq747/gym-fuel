//
//  FirebaseMealService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 12/12/2025.
//

import Foundation
import FirebaseFirestore

final class FirebaseMealService: MealService {
    private let db: Firestore
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }
    
    func fetchMeals(for userId: String, dayLogId: String) async throws -> [Meal] {
        
        let collection = mealsCollection(for: userId, dayLogId: dayLogId)
        
        let snapshot: QuerySnapshot = try await withCheckedThrowingContinuation { continuation in
                collection
                .order(by: "loggedAt", descending: false)
                .getDocuments { snapshot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let snapshot = snapshot {
                        continuation.resume(returning: snapshot)
                    } else {
                        let error = NSError(
                            domain: "FirebaseMealService",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Missing meals snapshot."]
                        )
                        continuation.resume(throwing: error)
                    }
                }
        }
        
        // map each doc to Meal type
        var result: [Meal] = []
        
        for doc in snapshot.documents {
            let data = doc.data()
            
            let storedUserId = data["userId"] as? String ?? userId
            let storedDayLogId = data["dayLogId"] as? String ?? dayLogId
            
            let loggedAt = ( data["loggedAt"] as? Timestamp)?.dateValue() ?? Date()
            let description = data["description"] as? String ?? ""
            
            let macroDict = data["macros"] as? [String: Any] ?? [:]
                   let macros = Macros(
                       calories: Self.double(from: macroDict["calories"]),
                       protein:  Self.double(from: macroDict["protein"]),
                       carbs:    Self.double(from: macroDict["carbs"]),
                       fat:      Self.double(from: macroDict["fat"])
                   )
                   
                   let meal = Meal(
                       id: doc.documentID,
                       userId: storedUserId,
                       dayLogId: storedDayLogId,
                       loggedAt: loggedAt,
                       description: description,
                       macros: macros
                   )
                   
                   result.append(meal)
        }
        return result.sorted { $0.loggedAt < $1.loggedAt }
    }
    
    func saveMeal(_ meal: Meal) async throws {
        
        let docRef = mealDocument(for: meal)
        
        let data: [String: Any] = [
               "userId": meal.userId,
               "dayLogId": meal.dayLogId,
               "loggedAt": meal.loggedAt,
               "description": meal.description,
               "macros": [
                   "calories": meal.macros.calories,
                   "protein":  meal.macros.protein,
                   "carbs":    meal.macros.carbs,
                   "fat":      meal.macros.fat
               ],
               "updatedAt": FieldValue.serverTimestamp()
           ]
        
        try await withCheckedThrowingContinuation{ (continuation: CheckedContinuation<Void,Error>) in
            docRef.setData(data) { err in
                if let err = err {
                    continuation.resume(throwing: err)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
    }
    
    func deleteMeal(_ meal: Meal) async throws {
        let docRef = mealDocument(for: meal)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
             docRef.delete { error in
                 if let error = error {
                     continuation.resume(throwing: error)
                 } else {
                     continuation.resume(returning: ())
                 }
             }
         }    }
    
    // /users/{userId}/dayLogs/{dayLogId}/meals
    private func mealsCollection(for userId: String, dayLogId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("dayLogs").document(dayLogId).collection("meals")
    }
    
    // /users/{userId}/dayLogs/{dayLogId}/meals/{mealId}
    private func mealDocument(for meal: Meal) -> DocumentReference {
        mealsCollection(for: meal.userId, dayLogId: meal.dayLogId).document(meal.id)
    }
    
    /// Safely convert Firestore numeric fields (Int/Double/NSNumber) to Double.
    private static func double(from any: Any?, default defaultValue: Double = 0) -> Double {
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        if let n = any as? NSNumber { return n.doubleValue }
        return defaultValue
    }

}

