//
//  PhaseService.swift
//  GymFuel
//

import Foundation

/// What a current-phase read found, and where it came from.
struct PhaseFetch: Equatable, Sendable {
    let phase: Phase?
    /// `false` when Firestore answered from its local cache. An empty cache read
    /// proves nothing — never start or repair a phase on the strength of one.
    let isFromServer: Bool
}

/// Reads and writes the `users/{uid}/phases` collection.
protocol PhaseService: Sendable {
    /// The phase in force: the most recently started one.
    func fetchCurrentPhase(for userId: String) async throws -> PhaseFetch

    /// Writes the whole document, **replacing** any phase with the same key — so
    /// a same-day switch to Maintain cannot leave the old pace behind.
    func startPhase(_ phase: Phase, for userId: String) async throws

    /// Changes only the target weight on an existing phase. `nil` removes it.
    func updateTargetWeight(_ targetWeightKg: Double?, phaseKey: String, for userId: String) async throws
}
