//
//  HealthSyncCopy.swift
//  GymFuel
//

import Foundation

/// What the Weight Sync row and its alerts are allowed to say about Apple Health.
///
/// Pure: no UI, no HealthKit. **iOS never discloses whether a *read* was
/// granted**, so On means the last read returned a weight, and nothing may call
/// Off "denied" or "blocked" — an empty Health database looks the same.
enum HealthSyncCopy {

    static func status(isConnected: Bool, isSyncing: Bool) -> String {
        if isSyncing { return syncing }
        return isConnected ? "On" : "Off"
    }

    /// The second line: the newest day the last read found a weight for.
    static func detail(isSyncing: Bool, lastFoundDateKey: String?) -> String? {
        guard !isSyncing,
              let lastFoundDateKey,
              let date = DateKey.date(from: lastFoundDateKey) else { return nil }

        let day = date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        return "Last weight from Health · \(day)"
    }

    static let syncing = "Syncing…"

    /// As words, because no public URL scheme opens this page (App Review 2.5.1).
    static let settingsPath = "Settings → Privacy & Security → Health → Circa"

    /// What a tap says once iOS has asked. Its sheet will not appear again, and
    /// no API lets the app revoke a read, so both directions go through Settings.
    static func settingsHint(isConnected: Bool) -> (title: String, message: String) {
        if isConnected {
            return (
                "Syncing from Apple Health",
                "Circa reads your weight each time you open the app. To stop, go to \(settingsPath) and turn off Weight."
            )
        }
        return (
            "Turn on in Settings",
            "iOS asks only once. Go to \(settingsPath) and turn on Weight. If it's already on, your next weight saved to Apple Health will appear in Circa."
        )
    }
}
