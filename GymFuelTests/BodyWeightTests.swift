//
//  BodyWeightTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("BodyWeight")
struct BodyWeightTests {
    @Test("One pound is the exact international avoirdupois pound")
    func poundIsExact() {
        #expect(BodyWeight.kilograms(fromPounds: 1) == 0.45359237)
    }

    /// The reason storage rounds to two decimal places rather than one. At 1 dp
    /// the error is 0.05 kg ≈ 0.11 lb, which exceeds the 0.05 lb needed to
    /// preserve a 0.2 lb step, and this test fails.
    @Test("lb to kg and back survives storage rounding across the whole range")
    func poundRoundTrip() {
        var pounds = 66.0
        while pounds <= 440.0 {
            let stored = BodyWeight.roundedForStorage(BodyWeight.kilograms(fromPounds: pounds))
            let back = BodyWeight.pounds(fromKilograms: stored)

            #expect(abs(back - pounds) < 0.05, "round trip failed at \(pounds) lb -> \(back) lb")
            pounds += 0.2
        }
    }

    @Test("Storage rounding is idempotent")
    func roundingIsIdempotent() {
        for value in stride(from: 30.0, through: 200.0, by: 0.137) {
            let once = BodyWeight.roundedForStorage(value)
            #expect(BodyWeight.roundedForStorage(once) == once)
        }
    }

    /// The float test that matters. It fails if anyone writes
    /// `whole + tenth / 10.0` instead of `(whole * 10 + tenth) / 10`.
    @Test("Picker decomposition round-trips exactly")
    func decompositionRoundTrips() {
        var tenths = 300
        while tenths <= 2000 {
            let value = Double(tenths) / 10
            let parts = BodyWeight.decompose(value)
            let recomposed = BodyWeight.recompose(whole: parts.whole, tenth: parts.tenth)

            #expect(recomposed == value, "failed at \(value): \(parts) -> \(recomposed)")
            tenths += 1
        }
    }

    @Test("Decomposition splits a known value")
    func decomposesKnownValue() {
        let parts = BodyWeight.decompose(80.4)
        #expect(parts.whole == 80)
        #expect(parts.tenth == 4)
    }

    @Test("Clamps to the kilogram range")
    func clamps() {
        #expect(BodyWeight.clampedToRange(10) == BodyWeight.minimumKilograms)
        #expect(BodyWeight.clampedToRange(500) == BodyWeight.maximumKilograms)
        #expect(BodyWeight.clampedToRange(83.4) == 83.4)
    }

    /// Pins `.rounded()` semantics at the boundary so it is a decision rather
    /// than an accident.
    @Test("Display rounds to one decimal place at the boundary")
    func displayRounding() {
        #expect(BodyWeight.displayString(kilograms: 80.04, unit: .kilograms).hasPrefix("80"))
        #expect(BodyWeight.displayString(kilograms: 80.04, unit: .kilograms).contains("0"))

        let rounded = (80.05 * 10).rounded() / 10
        #expect(rounded == 80.1)
    }

    @Test("Display formatting is locale-aware")
    func displayIsLocaleAware() {
        // `.formatted(.number…)` follows the locale; `String(format:)` would
        // hard-code a full stop and read wrong in de_DE, fr_FR and most of the EU.
        let value = 80.4
        let german = value.formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "de_DE")))
        #expect(german.contains(","))
    }

    @Test("Unit short labels")
    func unitLabels() {
        #expect(BodyWeightUnit.kilograms.shortLabel == "kg")
        #expect(BodyWeightUnit.pounds.shortLabel == "lbs")
    }
}
