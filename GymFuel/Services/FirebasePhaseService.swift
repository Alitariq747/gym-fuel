//
//  FirebasePhaseService.swift
//  GymFuel
//

import FirebaseFirestore
import Foundation

final class FirebasePhaseService: @unchecked Sendable {
    private let db = Firestore.firestore()

    /// The persisted shape. `startDateKey` is stored only because the security
    /// rule asserts it against the document ID, as on `weighIns`.
    private struct PhaseDocument: Codable {
        var startDateKey: String
        var goalType: GoalType
        var goalPace: GoalPace?
        var pacePercentPerWeek: Double
        var startWeightKg: Double
        var targetWeightKg: Double?
        var startTargets: Macros
        var calorieAdjustment: Double
        var lastStepDecisionDateKey: String?
        var startedAt: Date
    }

    private func phasesCollection(for userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("phases")
    }

    private func decodePhase(from snapshot: QueryDocumentSnapshot) -> Phase? {
        do {
            let document = try snapshot.data(as: PhaseDocument.self)
            return Phase(
                startDateKey: snapshot.documentID,
                goalType: document.goalType,
                goalPace: document.goalPace,
                pacePercentPerWeek: document.pacePercentPerWeek,
                startWeightKg: document.startWeightKg,
                targetWeightKg: document.targetWeightKg,
                startTargets: document.startTargets,
                calorieAdjustment: document.calorieAdjustment,
                lastStepDecisionDateKey: document.lastStepDecisionDateKey,
                startedAt: document.startedAt
            )
        } catch {
            FirebaseTelemetryService.recordNonFatal(
                error,
                reason: "phase_decode_failed",
                metadata: ["documentID": snapshot.documentID]
            )
            return nil
        }
    }
}

extension FirebasePhaseService: PhaseService {
    /// Newest by `startedAt`, not by `startDateKey`.
    ///
    /// In normal use the two orders agree: `PhasePlanner` never gives a new phase
    /// a key earlier than the current one. They differ only when the debug seeder
    /// backdates a phase on an account that already has `phases/{today}` from
    /// onboarding — and phases cannot be deleted, so key order would leave the
    /// seeded phase unreachable.
    func fetchCurrentPhase(for userId: String) async throws -> PhaseFetch {
        let snapshot: QuerySnapshot = try await phasesCollection(for: userId)
            .order(by: "startedAt", descending: true)
            .limit(to: 1)
            .getDocuments()

        return PhaseFetch(
            phase: snapshot.documents.first.flatMap { decodePhase(from: $0) },
            isFromServer: !snapshot.metadata.isFromCache
        )
    }

    func fetchCachedPhase(for userId: String) async -> Phase? {
        do {
            let snapshot: QuerySnapshot = try await phasesCollection(for: userId)
                .order(by: "startedAt", descending: true)
                .limit(to: 1)
                .getDocuments(source: .cache)
            return snapshot.documents.first.flatMap { decodePhase(from: $0) }
        } catch {
            return nil
        }
    }

    /// - Important: the completion fires only on **server acknowledgement**.
    ///   Awaiting this while offline never resumes.
    func startPhase(_ phase: Phase, for userId: String) async throws {
        let document = PhaseDocument(
            startDateKey: phase.startDateKey,
            goalType: phase.goalType,
            goalPace: phase.goalPace,
            pacePercentPerWeek: phase.pacePercentPerWeek,
            startWeightKg: phase.startWeightKg,
            targetWeightKg: phase.targetWeightKg,
            startTargets: phase.startTargets,
            calorieAdjustment: phase.calorieAdjustment,
            lastStepDecisionDateKey: phase.lastStepDecisionDateKey,
            startedAt: phase.startedAt
        )
        var data = try Firestore.Encoder().encode(document)
        data["createdAt"] = FieldValue.serverTimestamp()
        data["updatedAt"] = FieldValue.serverTimestamp()

        let docRef = phasesCollection(for: userId).document(phase.startDateKey)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            // No merge: the new phase replaces the old document outright.
            docRef.setData(data) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// - Important: awaits server acknowledgement, like `startPhase`.
    func updateTargetWeight(_ targetWeightKg: Double?, phaseKey: String, for userId: String) async throws {
        let data: [String: Any] = [
            "targetWeightKg": targetWeightKg.map { $0 as Any } ?? FieldValue.delete(),
            "updatedAt": FieldValue.serverTimestamp(),
        ]
        let docRef = phasesCollection(for: userId).document(phaseKey)

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
}
