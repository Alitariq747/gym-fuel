//
//  WeighInService.swift
//  GymFuel
//

import Foundation

/// Reads and writes the `users/{uid}/weighIns` collection.
///
/// Ranges are expressed as `"yyyy-MM-dd"` keys rather than `Date`s, unlike
/// `LogEntryService`. `LogEntry.loggedAt` is genuinely an instant; a weigh-in's
/// identity is the local *day*, so the timezone decision belongs at the
/// ViewModel boundary where `Calendar` and `TimeZone` are already injected and
/// testable. Hiding a calendar inside the Firebase layer would make the one
/// behaviour most likely to be wrong the one behaviour hardest to test.
///
/// `throughKey` is **inclusive**, unlike `LogEntryService`'s exclusive `to:`. A
/// date key names a day, not a boundary instant, and `< "2026-09-13"` to mean
/// "through the 12th" reads fine and is wrong once.
protocol WeighInService: Sendable {
    /// Ascending by day. Lexicographic order on zero-padded keys is chronological.
    func fetchWeighIns(
        for userId: String,
        fromKey: String,
        throughKey: String
    ) async throws -> [WeighIn]

    func fetchLatestWeighIn(for userId: String) async throws -> WeighIn?

    /// A point read — no index, and serves from the local cache when offline.
    func fetchWeighIn(for userId: String, dateKey: String) async throws -> WeighIn?

    func saveWeighIn(_ weighIn: WeighIn, for userId: String) async throws

    /// Writes into Firestore's local cache without awaiting server
    /// acknowledgement, so the value appears immediately and syncs later.
    /// See the offline note on `saveWeighIn` in `FirebaseWeighInService`.
    func saveWeighInLocally(_ weighIn: WeighIn, for userId: String) throws
}
