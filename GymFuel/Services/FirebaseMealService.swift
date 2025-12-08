//
//  FirebaseMealService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 07/12/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseMealService {
    static let shared = FirebaseMealService() // self
    
    private let db = Firestore.firestore()
    private init() {}
    
    private func daysCollection(for uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("days")
    }
    
    private func mealsCollection(for uid: String, dayId: String) -> CollectionReference {
        daysCollection(for: uid).document(dayId).collection("meals")
    }
    
    func addManualMeal(for log: DayLog, description: String, calories: Double, protein: Double, carbs: Double, fat: Double, completion: @escaping(Result<(Meal,DayLog),Error>) -> Void) {
        
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])))
                        return
        }
        
        let uid = user.uid
        let dayId = log.id
        
        let mealCol = mealsCollection(for: uid, dayId: dayId)
        let mealRef = mealCol.document()
        
        let now = Date()
        
        let mealData: [String: Any] = [
            "description": description,
            "calories": calories,
            "protein": protein,
            "carbs": carbs,
            "fat": fat,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // create new DayLog for total macros / consumed now
        let newTotalCalories = log.totalCalories + calories
        let newTotalProtein = log.totalProtein + protein
        let newTotalCarbs = log.totalCarbs + carbs
        let newTotalFat = log.totalFat + fat
        
        let dayDocRef = daysCollection(for: uid).document(dayId)
        
        mealRef.setData(mealData) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let dayUpdate: [String: Any] = [
                "totalCalories": newTotalCalories,
                "totalProtein": newTotalProtein,
                "totalCarbs": newTotalCarbs,
                "totalFat": newTotalFat,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            dayDocRef.setData(dayUpdate) { error in
                if let error = error {
                    completion(.failure(error))
                }
                let meal = Meal(id: mealRef.documentID, description: description, calories: calories, protein: protein, carbs: carbs, fat: fat, createdAt: now)
                
                let updatedLog = DayLog(id: log.id, dateString: log.dateString, dayType: log.dayType, targetCalories: log.targetCalories, targetProtein: log.targetProtein, targetCarbs: log.targetCarbs, targetFat: log.targetFat, totalCalories: newTotalCalories, totalProtein: newTotalProtein, totalCarbs: newTotalCarbs, totalFat: newTotalFat)
                
                completion(.success((meal, updatedLog)))
            }
        }
        
    }
    
    func fetchMeals(for log: DayLog, completion: @escaping(Result<[Meal],Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey : "No user logged in"])))
            return
        }
        
        let uid = currentUser.uid
        let dayId = log.id
        
        mealsCollection(for: uid, dayId: dayId)
            .order(by: "createdAt", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let snapshot = snapshot else {
                    completion(.success([]))
                    return
                }
                
                let meals: [Meal] = snapshot.documents.compactMap { doc in
                    let data = doc.data()
                    let description = data["description"] as? String ?? ""
                    let calories = data["calories"] as? Double ?? 0
                    let protein = data["protein"] as? Double ?? 0
                    let carbs = data["carbs"] as? Double ?? 0
                    let fat = data["fat"] as? Double ?? 0
                    
                    let ts = data["createdAt"] as? Timestamp
                    let date = ts?.dateValue()
                    
                    return Meal(id: doc.documentID, description: description, calories: calories, protein: protein, carbs: carbs, fat: fat, createdAt: date)
                    
                }
                
                completion(.success(meals))
            }
    }
}
