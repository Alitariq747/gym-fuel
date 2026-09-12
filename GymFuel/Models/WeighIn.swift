//
//  WeighIn.swift
//  GymFuel
//

import Foundation


enum WeighInSource: String, Codable, Equatable, Hashable, Sendable {
    case manual
    case healthKit

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = WeighInSource(rawValue: rawValue) ?? .manual
    }
}

/// One recorded body weight, owning a single local calendar day.
///
/// `dateKey` **is** the Firestore document ID (`"yyyy-MM-dd"`, see `DateKey`), so
/// re-weighing on the same day overwrites rather than appending: a day has one
/// weight. `id` is a computed alias rather than a second stored string, because
/// two stored fields that must stay equal is a bug waiting to happen.
///
/// There is no `userId` field — the document path already carries the owner, and
/// the security rule asserts `dateKey` instead. That follows the
/// `dailyMacroTargets` shape rather than the `logEntries` one.
struct WeighIn: Identifiable, Equatable, Hashable, Sendable {
    /// `"yyyy-MM-dd"` in the timezone the device was in when it was recorded.
    let dateKey: String
    let weightKg: Double
    /// The instant of recording. Kept for provenance, for HealthKit's
    /// `startDate` later, and because with `dateKey` it recovers the UTC offset
    /// in force at write time without storing a timezone field.
    let loggedAt: Date
    let source: WeighInSource

    var id: String { dateKey }

    init(dateKey: String, weightKg: Double, loggedAt: Date = Date(), source: WeighInSource = .manual) {
        self.dateKey = dateKey
        self.weightKg = weightKg
        self.loggedAt = loggedAt
        self.source = source
    }

    /// Builds a weigh-in for the local day containing `date`.
    init(
        recordedAt date: Date = Date(),
        weightKg: Double,
        source: WeighInSource = .manual,
        timeZone: TimeZone = .current
    ) {
        self.init(
            dateKey: DateKey.key(for: date, timeZone: timeZone),
            weightKg: weightKg,
            loggedAt: date,
            source: source
        )
    }
}
