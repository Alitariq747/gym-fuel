//
//  FirebaseWeighInService.swift
//  GymFuel
//

import FirebaseFirestore
import Foundation

final class FirebaseWeighInService: @unchecked Sendable {
    private let db = Firestore.firestore()

    /// The persisted shape. No `id` — the document ID is the authority, and
    /// `dateKey` is stored only because the security rule asserts it against the
    /// document ID. `Date` rides the Firestore Codable bridge, as everywhere
    /// else in the app.
    private struct WeighInDocument: Codable {
        var dateKey: String
        var weightKg: Double
        var loggedAt: Date
        var source: WeighInSource
    }

    private func weighInsCollection(for userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("weighIns")
    }

    private func decodeWeighIn(from snapshot: DocumentSnapshot) throws -> WeighIn {
        let document = try snapshot.data(as: WeighInDocument.self)
        return WeighIn(
            dateKey: snapshot.documentID,
            weightKg: document.weightKg,
            loggedAt: document.loggedAt,
            source: document.source
        )
    }

    /// One unreadable row must never blank the chart, so decode failures are
    /// skipped and reported rather than thrown — matching `FirebaseLogEntryService`.
    private func decodeWeighIn(skippingFailuresFrom snapshot: QueryDocumentSnapshot) -> WeighIn? {
        do {
            return try decodeWeighIn(from: snapshot)
        } catch {
            FirebaseTelemetryService.recordNonFatal(
                error,
                reason: "weigh_in_decode_failed",
                metadata: ["documentID": snapshot.documentID]
            )
            return nil
        }
    }

    private func encodeWeighIn(_ weighIn: WeighIn) throws -> [String: Any] {
        let document = WeighInDocument(
            dateKey: weighIn.dateKey,
            weightKg: weighIn.weightKg,
            loggedAt: weighIn.loggedAt,
            source: weighIn.source
        )
        return try Firestore.Encoder().encode(document)
    }
}

extension FirebaseWeighInService: WeighInService {
    func fetchWeighIns(
        for userId: String,
        fromKey: String,
        throughKey: String
    ) async throws -> [WeighIn] {
        let snapshot: QuerySnapshot = try await weighInsCollection(for: userId)
            .whereField("dateKey", isGreaterThanOrEqualTo: fromKey)
            .whereField("dateKey", isLessThanOrEqualTo: throughKey)
            .order(by: "dateKey", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { decodeWeighIn(skippingFailuresFrom: $0) }
    }

    func fetchLatestWeighIn(for userId: String) async throws -> WeighIn? {
        let snapshot: QuerySnapshot = try await weighInsCollection(for: userId)
            .order(by: "dateKey", descending: true)
            .limit(to: 1)
            .getDocuments()

        return snapshot.documents.compactMap { decodeWeighIn(skippingFailuresFrom: $0) }.first
    }

    func fetchWeighIn(for userId: String, dateKey: String) async throws -> WeighIn? {
        let snapshot = try await weighInsCollection(for: userId).document(dateKey).getDocument()
        guard snapshot.exists else { return nil }

        do {
            return try decodeWeighIn(from: snapshot)
        } catch {
            FirebaseTelemetryService.recordNonFatal(
                error,
                reason: "weigh_in_decode_failed",
                metadata: ["documentID": snapshot.documentID]
            )
            return nil
        }
    }

    /// - Important: the completion fires only on **server acknowledgement**.
    ///   Awaiting this while offline never resumes — the caller must branch on
    ///   `NetworkMonitor` and use `saveWeighInLocally` instead.
    func saveWeighIn(_ weighIn: WeighIn, for userId: String) async throws {
        let data = try encodeWeighIn(weighIn)
        let docRef = weighInsCollection(for: userId).document(weighIn.dateKey)

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

    func saveWeighInLocally(_ weighIn: WeighIn, for userId: String) throws {
        let data = try encodeWeighIn(weighIn)
        let docRef = weighInsCollection(for: userId).document(weighIn.dateKey)
        docRef.setData(data, merge: true)
    }
}
