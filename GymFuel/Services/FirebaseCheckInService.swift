//
//  FirebaseCheckInService.swift
//  GymFuel
//

import FirebaseFirestore
import Foundation

final class FirebaseCheckInService: @unchecked Sendable {
    private let db = Firestore.firestore()

    /// The persisted shape. `dueDateKey` is stored only because the security
    /// rule asserts it against the document ID, as on `phases`. Optional fields
    /// are omitted when `nil`.
    private struct CheckInDocument: Codable {
        var dueDateKey: String
        var phaseStartDateKey: String
        var decision: CheckIn.Decision
        var response: CheckIn.Response
        var paceKgPerWeek: Double?
        var goalKgPerWeek: Double?
        var weighInCount: Int?
        var windowDays: Int?
        var loggedDays: Int
        var averageLoggedCalories: Double
        var suggestedDelta: Double?
        var targetsBefore: Macros
        var targetsAfter: Macros
        var completedDateKey: String
        var completedAt: Date
    }

    private func checkInsCollection(for userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("checkIns")
    }

    private func phaseDocument(_ phaseKey: String, for userId: String) -> DocumentReference {
        db.collection("users").document(userId).collection("phases").document(phaseKey)
    }

    private func decodeCheckIn(from snapshot: QueryDocumentSnapshot) -> CheckIn? {
        do {
            let document = try snapshot.data(as: CheckInDocument.self)
            return CheckIn(
                dueDateKey: snapshot.documentID,
                phaseStartDateKey: document.phaseStartDateKey,
                decision: document.decision,
                response: document.response,
                paceKgPerWeek: document.paceKgPerWeek,
                goalKgPerWeek: document.goalKgPerWeek,
                weighInCount: document.weighInCount,
                windowDays: document.windowDays,
                loggedDays: document.loggedDays,
                averageLoggedCalories: document.averageLoggedCalories,
                suggestedDelta: document.suggestedDelta,
                targetsBefore: document.targetsBefore,
                targetsAfter: document.targetsAfter,
                completedDateKey: document.completedDateKey,
                completedAt: document.completedAt
            )
        } catch {
            FirebaseTelemetryService.recordNonFatal(
                error,
                reason: "check_in_decode_failed",
                metadata: ["documentID": snapshot.documentID]
            )
            return nil
        }
    }

    /// The check-in and the phase update, in one batch.
    private func makeBatch(
        _ checkIn: CheckIn,
        phaseUpdate: PhaseDecisionUpdate?,
        for userId: String
    ) throws -> WriteBatch {
        let document = CheckInDocument(
            dueDateKey: checkIn.dueDateKey,
            phaseStartDateKey: checkIn.phaseStartDateKey,
            decision: checkIn.decision,
            response: checkIn.response,
            paceKgPerWeek: checkIn.paceKgPerWeek,
            goalKgPerWeek: checkIn.goalKgPerWeek,
            weighInCount: checkIn.weighInCount,
            windowDays: checkIn.windowDays,
            loggedDays: checkIn.loggedDays,
            averageLoggedCalories: checkIn.averageLoggedCalories,
            suggestedDelta: checkIn.suggestedDelta,
            targetsBefore: checkIn.targetsBefore,
            targetsAfter: checkIn.targetsAfter,
            completedDateKey: checkIn.completedDateKey,
            completedAt: checkIn.completedAt
        )
        var data = try Firestore.Encoder().encode(document)
        data["createdAt"] = FieldValue.serverTimestamp()
        data["updatedAt"] = FieldValue.serverTimestamp()

        let batch = db.batch()
        batch.setData(data, forDocument: checkInsCollection(for: userId).document(checkIn.dueDateKey))

        if let phaseUpdate {
            var fields: [String: Any] = [
                "lastStepDecisionDateKey": phaseUpdate.decisionDateKey,
                "updatedAt": FieldValue.serverTimestamp(),
            ]
            if let calorieAdjustment = phaseUpdate.calorieAdjustment {
                fields["calorieAdjustment"] = calorieAdjustment
            }
            // An update, not a merge: a phase that isn't there fails the batch.
            batch.updateData(fields, forDocument: phaseDocument(phaseUpdate.phaseKey, for: userId))
        }

        return batch
    }
}

extension FirebaseCheckInService: CheckInService {
    func fetchLatestCheckIn(for userId: String) async throws -> CheckIn? {
        let snapshot: QuerySnapshot = try await checkInsCollection(for: userId)
            .order(by: "completedAt", descending: true)
            .limit(to: 1)
            .getDocuments()

        return snapshot.documents.first.flatMap { decodeCheckIn(from: $0) }
    }

    /// - Important: the completion fires only on **server acknowledgement**.
    ///   Awaiting this while offline never resumes — the caller must branch on
    ///   `NetworkMonitor` and use `saveCheckInLocally` instead.
    func saveCheckIn(_ checkIn: CheckIn, phaseUpdate: PhaseDecisionUpdate?, for userId: String) async throws {
        let batch = try makeBatch(checkIn, phaseUpdate: phaseUpdate, for: userId)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            batch.commit { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func saveCheckInLocally(_ checkIn: CheckIn, phaseUpdate: PhaseDecisionUpdate?, for userId: String) throws {
        try makeBatch(checkIn, phaseUpdate: phaseUpdate, for: userId).commit()
    }
}
