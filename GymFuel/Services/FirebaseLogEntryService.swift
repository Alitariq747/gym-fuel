//
//  FirebaseLogEntryService.swift
//  GymFuel
//
//  Created by Ahmad on 15/04/2026.
//

import FirebaseFirestore
import Foundation

final class FirebaseLogEntryService: @unchecked Sendable {
    private final class ListenerCancellationBox: @unchecked Sendable {
        let listener: ListenerRegistration

        init(listener: ListenerRegistration) {
            self.listener = listener
        }
    }

    private let db = Firestore.firestore()

    private struct LogEntryDocument: Codable {
        var userId: String
        var source: LogEntrySource
        var status: LogEntryStatus
        var loggedAt: Date
        var type: LogEntryType
        var title: String
        var rawInput: String
        var detail: String?
        var feedback: LogEntryFeedback?
        var image: LogEntryImage?
        var imageUploadStatus: LogEntryImageUploadStatus?
    }

    private func entriesCollection(for userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("logEntries")
    }

    private func decodeEntry(from snapshot: QueryDocumentSnapshot) throws -> LogEntry {
        let document = try snapshot.data(as: LogEntryDocument.self)
        return LogEntry(
            id: snapshot.documentID,
            userId: document.userId,
            source: document.source,
            status: document.status,
            loggedAt: document.loggedAt,
            type: document.type,
            title: document.title,
            rawInput: document.rawInput,
            detail: document.detail,
            feedback: document.feedback,
            image: document.image,
            imageUploadStatus: document.imageUploadStatus
        )
    }

    private func encodeEntry(_ entry: LogEntry) throws -> [String: Any] {
        let document = LogEntryDocument(
            userId: entry.userId,
            source: entry.source,
            status: entry.status,
            loggedAt: entry.loggedAt,
            type: entry.type,
            title: entry.title,
            rawInput: entry.rawInput,
            detail: entry.detail,
            feedback: entry.feedback,
            image: entry.image,
            imageUploadStatus: entry.imageUploadStatus
        )
        return try Firestore.Encoder().encode(document)
    }
}
extension FirebaseLogEntryService: LogEntryService {
    func observeEntries(
        for userId: String,
        from startDate: Date,
        to endDate: Date,
        onChange: @escaping LogEntryObservationHandler
    ) -> LogEntryObservationCancellation {
        let listener = entriesCollection(for: userId)
            .whereField("loggedAt", isGreaterThanOrEqualTo: startDate)
            .whereField("loggedAt", isLessThan: endDate)
            .order(by: "loggedAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                guard let snapshot else { return }

                do {
                    let entries = try snapshot.documents.map(self.decodeEntry)
                    onChange(.success(entries))
                } catch {
                    onChange(.failure(error))
                }
            }

        let box = ListenerCancellationBox(listener: listener)
        return {
            box.listener.remove()
        }
    }

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

    func saveEntryLocally(_ entry: LogEntry) throws {
        let data = try encodeEntry(entry)
        let docRef = entriesCollection(for: entry.userId).document(entry.id)
        docRef.setData(data, merge: true)
    }

    func updateEntryLocally(_ entry: LogEntry) throws {
        try saveEntryLocally(entry)
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
            docRef.setData(data, merge: true) { error in
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
