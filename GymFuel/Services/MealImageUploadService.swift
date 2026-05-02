//
//  MealImageUploadService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 16/04/2026.
//

import FirebaseStorage
import Foundation

protocol MealImageUploadService: Sendable {
    func uploadMealImage(_ imageData: Data, userId: String, entryId: String) async throws -> String
    func fetchMealImageData(at storagePath: String, maxSizeBytes: Int64) async throws -> Data
    func deleteMealImage(at storagePath: String) async throws
}

enum MealImageUploadError: LocalizedError {
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "We couldn't upload that meal photo."
        }
    }
}

final class FirebaseMealImageUploadService: MealImageUploadService, @unchecked Sendable {
    private let storage = Storage.storage()

    func uploadMealImage(_ imageData: Data, userId: String, entryId: String) async throws -> String {
        guard imageData.isEmpty == false else {
            throw MealImageUploadError.invalidImageData
        }

        let storagePath = mealImageStoragePath(for: userId, entryId: entryId)
        let reference = storage.reference(withPath: storagePath)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.putData(imageData, metadata: metadata) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }

        return storagePath
    }

    func deleteMealImage(at storagePath: String) async throws {
        let reference = storage.reference(withPath: storagePath)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.delete { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func fetchMealImageData(at storagePath: String, maxSizeBytes: Int64 = 5 * 1024 * 1024) async throws -> Data {
        let reference = storage.reference(withPath: storagePath)
        return try await reference.data(maxSize: maxSizeBytes)
    }

    private func mealImageStoragePath(for userId: String, entryId: String) -> String {
        "users/\(userId)/mealImages/\(entryId).jpg"
    }
}
