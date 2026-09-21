//
//  MealBreakdown.swift
//  GymFuel
//
//  Created by Ahmad on 21/09/2026.
//
//  The editable tree inside one meal. The shape and every rule about it live in
//  `meal-contract.md`, shared with the backend and changeable in neither Step 5
//  nor Step 6 alone. Section references below point there.
//

import Foundation

// MARK: - Failure-tolerant decoding (§2)

/// Wraps a value so a malformed payload decodes as `nil` rather than throwing.
///
/// `FirebaseLogEntryService.decodeEntry(skippingFailuresFrom:)` compactMaps decode
/// failures away, so a field the client cannot read does not surface an error — it
/// removes that meal from the user's timeline. This is what lets everything inside
/// the tree stay non-optional: nothing in there can escalate to killing the entry.
@propertyWrapper
struct Lenient<T: Codable & Equatable & Hashable & Sendable>: Codable, Equatable, Hashable, Sendable {
    var wrappedValue: T?

    init(wrappedValue: T?) { self.wrappedValue = wrappedValue }

    init(from decoder: Decoder) throws {
        wrappedValue = try? T(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let wrappedValue {
            try container.encode(wrappedValue)
        } else {
            try container.encodeNil()
        }
    }
}

extension KeyedDecodingContainer {
    /// A missing key is absence, not failure — every document written before this
    /// contract is in that case.
    func decode<T>(_ type: Lenient<T>.Type, forKey key: Key) throws -> Lenient<T> {
        try decodeIfPresent(type, forKey: key) ?? Lenient<T>(wrappedValue: nil)
    }
}

extension KeyedEncodingContainer {
    /// Omit `nil`, so a wrapped field behaves like every other optional here and
    /// §7 stays the single explanation of how a field is actually cleared.
    mutating func encode<T>(_ value: Lenient<T>, forKey key: Key) throws {
        guard let wrapped = value.wrappedValue else { return }
        try encode(wrapped, forKey: key)
    }
}

// MARK: - Provenance (§5)

/// Where a number came from. Orthogonal to whether the user corrected the amount,
/// which is `MealAmount.isAdjusted` — one enum cannot say "the user halved a label
/// value", so the two axes stay apart.
enum MealProvenance: String, Codable, Equatable, Hashable, Sendable {
    /// The model's guess.
    case estimated
    /// A label or documented reference; `sourceNote` names it.
    case reference
    /// The user typed the meal total. Meal-level only.
    case userTotal

    /// Unknown reads as an estimate — never as more certainty than we have.
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = MealProvenance(rawValue: rawValue) ?? .estimated
    }
}

// MARK: - Amount (§3)

/// An edit writes `adjustedQuantity` and nothing else, so the first estimate is
/// never lost. That buys no compounding (2 → 3 → 1.5 always computes from 2), exact
/// round trips, a derived "user-adjusted" that cannot drift, and removal as `0`.
struct MealAmount: Codable, Equatable, Hashable, Sendable {
    /// As first estimated. Never overwritten, by the client or the server.
    var quantity: Double
    /// Free text — "tbsp", "roti", "katori", "g". Never converted to anything.
    var unit: String
    /// The user's correction. `nil` until they make one; `0` means removed.
    var adjustedQuantity: Double? = nil

    var effectiveQuantity: Double { adjustedQuantity ?? quantity }

    /// What to multiply stored nutrition by. Guards the contract's only division:
    /// you cannot scale up from nothing.
    var scale: Double { quantity > 0 ? effectiveQuantity / quantity : 1 }

    var isAdjusted: Bool { adjustedQuantity != nil && adjustedQuantity != quantity }
}

// MARK: - Nodes (§3)

/// A material part of an item — the ghee in a karahi, the mayonnaise in a sandwich.
///
/// `nutrition` is always the nutrition for `amount.quantity`, the original estimate.
/// A contribution is `nutrition × amount.scale`, worked out at read time, so saving
/// an edit never rewrites a stored number.
struct MealComponent: Codable, Equatable, Hashable, Sendable, Identifiable {
    /// Opaque and stable forever. Server-generated; never parsed or rewritten here.
    var id: String
    var name: String
    /// `nil` ⇒ nothing to correct; rendered read-only.
    var amount: MealAmount? = nil
    /// `nil` ⇒ descriptive only: shown without a number, contributes nothing.
    var nutrition: Macros? = nil
    var source: MealProvenance? = nil
    /// "USDA 05062, chicken breast, roasted".
    var sourceNote: String? = nil
    /// "Ghee, not oil".
    var assumption: String? = nil

    var resolvedSource: MealProvenance { source ?? .estimated }

    /// A part is correctable exactly when it carries both a number and an amount
    /// to scale that number by. §4's rule needs no special case: a
    /// component-priced item has no nutrition of its own, so this is already
    /// false for it, and its parts carry the handle instead.
    var isAmountEditable: Bool { nutrition != nil && amount != nil }
}

/// One thing the user ate. Two roti is one item, not two.
///
/// `nutrition != nil` asserts *my components are prose*; `nutrition == nil` asserts
/// *my components are the arithmetic*. Mutually exclusive by construction, which is
/// how §4 makes double counting unreachable rather than merely unlikely.
struct MealItem: Codable, Equatable, Hashable, Sendable, Identifiable {
    var id: String
    var name: String
    var amount: MealAmount? = nil
    /// `nil` ⟺ this item is priced by its components.
    var nutrition: Macros? = nil
    var components: [MealComponent] = []
    var source: MealProvenance? = nil
    var sourceNote: String? = nil
    var assumption: String? = nil

    var resolvedSource: MealProvenance { source ?? .estimated }

    /// See `MealComponent.isAmountEditable`.
    var isAmountEditable: Bool { nutrition != nil && amount != nil }
}

// MARK: - Breakdown

/// Every item in one meal. Exactly two levels deep, never recursive.
struct MealBreakdown: Codable, Equatable, Hashable, Sendable {
    /// Bumped only when an existing field changes meaning — adding a field does
    /// not bump it, because unknown keys already decode fine.
    static let currentVersion = 1

    /// Absent reads as version 1.
    var version: Int? = nil
    var items: [MealItem]

    var resolvedVersion: Int { version ?? Self.currentVersion }

    /// A future shape is kept in storage and not rendered: its fields no longer
    /// mean what this build thinks, so the entry falls back to its totals.
    var isSupported: Bool { resolvedVersion <= Self.currentVersion }
}
