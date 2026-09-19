//
//  WeighInDeletion.swift
//  GymFuel
//

import Foundation

/// What the Weight screen may delete, and the weight the profile shows after.
/// Pure, so the rules are tested without Firestore.
enum WeighInDeletion {
    /// Typed weigh-ins only — a Health one would come back on the next import —
    /// and never the only one on screen, so the weight shown always comes from a
    /// weigh-in (decided 19 September).
    static func canDelete(_ weighIn: WeighIn, among weighIns: [WeighIn]) -> Bool {
        weighIn.source == .manual && weighIns.count > 1
    }

    /// The weight before `weighIn` when it was the newest, or nil when deleting it
    /// leaves the weight shown as it is.
    static func profileWeight(afterDeleting weighIn: WeighIn, among weighIns: [WeighIn]) -> Double? {
        guard weighIns.max(by: { $0.dateKey < $1.dateKey })?.dateKey == weighIn.dateKey else { return nil }

        return weighIns
            .filter { $0.dateKey != weighIn.dateKey }
            .max(by: { $0.dateKey < $1.dateKey })?
            .weightKg
    }
}
