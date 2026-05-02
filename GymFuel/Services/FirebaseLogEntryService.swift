//
//  FirebaseLogEntryService.swift
//  GymFuel
//
//  Created by Ahmad on 15/04/2026.
//

import FirebaseFirestore
import Foundation

final class FirebaseLogEntryService: @unchecked Sendable {
    private let db = Firestore.firestore()

    private struct LogEntryDocument: Codable {
        var userId: String
        var loggedAt: Date
        var type: LogEntryType
        var title: String
        var rawInput: String
        var detail: String?
        var feedback: LogEntryFeedback?
        var image: LogEntryImage?
    }

    private func entriesCollection(for userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("logEntries")
    }

    private func decodeEntry(from snapshot: QueryDocumentSnapshot) throws -> LogEntry {
        let document = try snapshot.data(as: LogEntryDocument.self)
        return LogEntry(
            id: snapshot.documentID,
            userId: document.userId,
            loggedAt: document.loggedAt,
            type: document.type,
            title: document.title,
            rawInput: document.rawInput,
            detail: document.detail,
            feedback: document.feedback,
            image: document.image
        )
    }

    private func encodeEntry(_ entry: LogEntry) throws -> [String: Any] {
        let document = LogEntryDocument(
            userId: entry.userId,
            loggedAt: entry.loggedAt,
            type: entry.type,
            title: entry.title,
            rawInput: entry.rawInput,
            detail: entry.detail,
            feedback: entry.feedback,
            image: entry.image
        )
        return try Firestore.Encoder().encode(document)
    }
}
extension FirebaseLogEntryService: LogEntryService {
    func fetchEntries(
        for userId: String,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [LogEntry] {
        let snapshot: QuerySnapshot = try await entriesCollection(for: userId)
            .whereField("loggedAt", isGreaterThanOrEqualTo: startDate)
            .whereField("loggedAt", isLessThan: endDate)
            .order(by: "loggedAt", descending: false)
            .getDocuments()

        return try snapshot.documents.map(decodeEntry)
    }

    func saveEntry(_ entry: LogEntry) async throws {
        let data = try encodeEntry(entry)
        let docRef = entriesCollection(for: entry.userId).document(entry.id)
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

    func updateEntry(_ entry: LogEntry) async throws {
        let data = try encodeEntry(entry)
        let docRef = entriesCollection(for: entry.userId).document(entry.id)

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

    func deleteEntry(userId: String, entryId: String) async throws {
        let docRef = entriesCollection(for: userId).document(entryId)

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
