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
    
    private struct SavedMealDocument: Codable {
        let userId: String
        let name: String
        let description: String?
        let macros: Macros
        let createdAt: Date
        @Lenient var breakdown: MealBreakdown? = nil
        let macrosProvenance: MealProvenance?
    }

    private func savedMealsCollection(for userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("savedMeals")
    }

    private func decodeSavedMeal(from snapshot: QueryDocumentSnapshot) throws -> SavedMeal {
        let document = try snapshot.data(as: SavedMealDocument.self)
        return SavedMeal(
            id: snapshot.documentID,
            userId: document.userId,
            name: document.name,
            description: document.description,
            macros: document.macros,
            createdAt: document.createdAt,
            breakdown: document.breakdown,
            macrosProvenance: document.macrosProvenance
        )
    }

    private func decodeSavedMeal(skippingFailuresFrom snapshot: QueryDocumentSnapshot) -> SavedMeal? {
        do {
            return try decodeSavedMeal(from: snapshot)
        } catch {
            FirebaseTelemetryService.recordNonFatal(
                error,
                reason: "saved_meal_decode_failed",
                metadata: ["documentID": snapshot.documentID]
            )
            return nil
        }
    }

    private func encodeSavedMeal(_ meal: SavedMeal) throws -> [String: Any] {
        try Firestore.Encoder().encode(
            SavedMealDocument(
                userId: meal.userId,
                name: meal.name,
                description: meal.description,
                macros: meal.macros,
                createdAt: meal.createdAt,
                breakdown: meal.breakdown,
                macrosProvenance: meal.macrosProvenance
            )
        )
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

        return snapshot.documents.compactMap { decodeSavedMeal(skippingFailuresFrom: $0) }
    }

    func saveMeal(_ meal: SavedMeal) async throws {
        let docRef = savedMealsCollection(for: meal.userId).document(meal.id)

        var data = try encodeSavedMeal(meal)
        data["updatedAt"] = FieldValue.serverTimestamp()

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
        var data = try encodeSavedMeal(meal)
        data["updatedAt"] = FieldValue.serverTimestamp()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            // A full replace, for the reason `updateEntry` uses one: encoding
            // omits a nil field, so a superseded breakdown would survive a merge.
            // It also writes a meal whose document has gone, which `updateData`
            // refuses to do.
            docRef.setData(data) { error in
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
}
