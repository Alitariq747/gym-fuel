//
//  TodaySnapshotStore.swift
//  GymFuel
//
//  Shared with the widget extension: the app saves and clears, the widget loads.
//

import Foundation
import WidgetKit

enum TodaySnapshotStore {
    struct MissingAppGroup: Error {}

    private static let fileURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: "group.com.ahmad.GymFuel")?
        .appendingPathComponent("today-snapshot.json")

    static func load() -> TodaySnapshot? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(TodaySnapshot.self, from: data)
    }

    /// Lock Screen widgets read this while the phone is locked, so it must stay
    /// readable after the first unlock — never `.completeFileProtection`.
    static func save(_ snapshot: TodaySnapshot) throws {
        guard let fileURL else { throw MissingAppGroup() }
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func clear() {
        guard let fileURL else { return }
        try? FileManager.default.removeItem(at: fileURL)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
