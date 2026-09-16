//
//  CheckInService.swift
//  GymFuel
//

import Foundation

/// What a check-in answer writes onto its phase.
struct PhaseDecisionUpdate: Equatable, Sendable {
    let phaseKey: String
    /// The new absolute adjustment on **Use**; `nil` on **Keep my target**.
    let calorieAdjustment: Double?
    /// Starts the 14-day wait on both.
    let decisionDateKey: String
}

/// Reads and writes the `users/{uid}/checkIns` collection.
protocol CheckInService: Sendable {
    /// The most recently completed check-in, from any phase.
    func fetchLatestCheckIn(for userId: String) async throws -> CheckIn?

    /// Writes the check-in and, if given, the phase update in **one batch**.
    /// Values are absolute, so a retry cannot step twice. The phase half is an
    /// update, so a missing phase fails the whole batch rather than being
    /// half-created.
    func saveCheckIn(_ checkIn: CheckIn, phaseUpdate: PhaseDecisionUpdate?, for userId: String) async throws

    /// The same batch, committed into the local cache without awaiting the
    /// server, for offline. See `saveCheckIn` in `FirebaseCheckInService`.
    func saveCheckInLocally(_ checkIn: CheckIn, phaseUpdate: PhaseDecisionUpdate?, for userId: String) throws
}
