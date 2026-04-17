//
//  FirebaseSavedMealService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 04/03/2026.
//

import FirebaseFirestore
import Foundation

final class FirebaseSavedMealService: SavedMealService, @unchecked Sendable {
    private let db = Firestore.firestore()

    private func savedMealsCollection(for userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("savedMeals")
    }

    func fetchSavedMeals(for userId: String) async throws -> [SavedMeal] {
        let collection = savedMealsCollection(for: userId)

        let snapshot: QuerySnapshot = try await withCheckedThrowingContinuation { continuation in
            collection
                .order(by: "createdAt", descending: true)
                .getDocuments { snapshot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let snapshot = snapshot {
                        continuation.resume(returning: snapshot)
                    } else {
                        let error = NSError(
                            domain: "FirebaseSavedMealService",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Missing saved meals snapshot."]
                        )
                        continuation.resume(throwing: error)
                    }
                }
        }

        var result: [SavedMeal] = []

        for doc in snapshot.documents {
            let data = doc.data()
            let storedUserId = data["userId"] as? String ?? userId
            let name = data["name"] as? String ?? "Saved meal"
            let description = data["description"] as? String
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            let lastUsedAt = (data["lastUsedAt"] as? Timestamp)?.dateValue()

            let macroDict = data["macros"] as? [String: Any] ?? [:]
            let macros = Macros(
                calories: Self.double(from: macroDict["calories"]),
                protein: Self.double(from: macroDict["protein"]),
                carbs: Self.double(from: macroDict["carbs"]),
                fat: Self.double(from: macroDict["fat"])
            )

            let meal = SavedMeal(
                id: doc.documentID,
                userId: storedUserId,
                name: name,
                description: description,
                macros: macros,
                createdAt: createdAt,
                lastUsedAt: lastUsedAt
            )
            result.append(meal)
        }

        return result
    }

    func saveMeal(_ meal: SavedMeal) async throws {
        let docRef = savedMealsCollection(for: meal.userId).document(meal.id)

        var data: [String: Any] = [
            "userId": meal.userId,
            "name": meal.name,
            "macros": [
                "calories": meal.macros.calories,
                "protein": meal.macros.protein,
                "carbs": meal.macros.carbs,
                "fat": meal.macros.fat
            ],
            "createdAt": meal.createdAt,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if let description = meal.description, !description.isEmpty {
            data["description"] = description
        }

        if let lastUsedAt = meal.lastUsedAt {
            data["lastUsedAt"] = lastUsedAt
        }

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

    func updateMeal(_ meal: SavedMeal) async throws {
        let docRef = savedMealsCollection(for: meal.userId).document(meal.id)
        var data: [String: Any] = [
            "name": meal.name,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        data["macros"] = [
            "calories": meal.macros.calories,
            "protein": meal.macros.protein,
            "carbs": meal.macros.carbs,
            "fat": meal.macros.fat
        ]
        if let description = meal.description, !description.isEmpty {
            data["description"] = description
        }
        if let lastUsedAt = meal.lastUsedAt {
            data["lastUsedAt"] = lastUsedAt
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            docRef.updateData(data) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func deleteMeal(userId: String, mealId: String) async throws {
        let docRef = savedMealsCollection(for: userId).document(mealId)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            docRef.delete { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private static func double(from any: Any?, default defaultValue: Double = 0) -> Double {
        if let d = any as? Double { return d.isFinite ? d : defaultValue }
        if let i = any as? Int { return Double(i) }
        if let n = any as? NSNumber {
            let value = n.doubleValue
            return value.isFinite ? value : defaultValue
        }
        return defaultValue
    }
}
