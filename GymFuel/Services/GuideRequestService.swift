//
//  GuideRequestService.swift
//  GymFuel
//

import FirebaseFirestore
import Foundation

/// A food someone asked the portion guide to add. Kept under their account, so
/// deleting the account deletes it; `firestore.rules` lets only them write it once.
protocol GuideRequestService: Sendable {
    func sendRequest(food: String, userId: String) async throws
}

struct FirebaseGuideRequestService: GuideRequestService {
    func sendRequest(food: String, userId: String) async throws {
        _ = try await Firestore.firestore()
            .collection("users").document(userId).collection("guideRequests")
            .addDocument(data: ["food": food, "createdAt": FieldValue.serverTimestamp()])
    }
}
