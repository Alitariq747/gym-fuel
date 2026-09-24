//
//  HealthSyncCopy.swift
//  GymFuel
//

import Foundation

/// What the Weight Sync row is allowed to say about Apple Health.
///
/// Pure: no UI, no HealthKit. The rule lives here rather than in the row because
/// the row got it wrong — **iOS never discloses whether a *read* was granted**,
/// so nothing may render as "Connected", "denied" or "blocked".
/// `HealthWeightSyncService.isConnected` records that the user opted in and
/// nothing more; beyond that the only honest report is what the last read
/// returned.
enum HealthSyncCopy {

    /// The row's trailing value. Names the user's own choice, never Apple's
    /// answer to it.
    static func status(isConnected: Bool, isSyncing: Bool) -> String {
        if isSyncing { return syncing }
        return isConnected ? "On" : "Off"
    }

    /// The second line: what the last completed read found. Nil while there is
    /// nothing yet to report.
    static func detail(
        isConnected: Bool,
        isSyncing: Bool,
        hasSynced: Bool,
        lastFoundDateKey: String?
    ) -> String? {
        guard isConnected, !isSyncing, hasSynced else { return nil }

        guard let lastFoundDateKey,
              let date = DateKey.date(from: lastFoundDateKey) else { return nothingFound }

        let day = date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        return "Last weight from Health · \(day)"
    }

    static let syncing = "Syncing…"

    /// Said without blaming the user: zero samples means a refused read *or* an
    /// empty Health database, and the two are indistinguishable from here. It
    /// points at the one page that can settle it — as words, because no public
    /// URL scheme opens that page (App Review 2.5.1).
    static let nothingFound = "No weights found — check Health → Sharing → Apps."

    /// Shown when the row is switched on but iOS will not raise its sheet again,
    /// so the tap appears to have done nothing.
    ///
    /// States a fact about iOS, never about the user's answer: whether the read
    /// was allowed is not something this app is told.
    static let asksOnceTitle = "Apple Health asks only once"
    static let asksOnceBody = """
        iOS won't show its permission sheet again. If your weights don't appear, \
        open Health → Sharing → Apps → Circa and turn on Weight.
        """
}
