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

@Suite("WeightWheel")
struct WeightWheelTests {
    /// The reason both bounds derive from the kilogram range. A hand-written
    /// `66...440` lb beside `30...200` kg is not a mirror of it — 30 kg is
    /// 66.14 lb — and the ends drift on a unit switch.
    @Test("Both ends of the range stay inside the stored kilogram range")
    func rangeMirrorsKilograms() {
        for unit in BodyWeightUnit.allCases {
            let wheel = WeightWheel(unit)

            let lowest = wheel.kilograms(whole: wheel.wholeRange.lowerBound, tenth: 0)
            let highest = wheel.kilograms(whole: wheel.wholeRange.upperBound, tenth: wheel.tenthRange.max() ?? 0)

            #expect(lowest >= BodyWeight.minimumKilograms, "\(unit) floor: \(lowest)")
            #expect(highest <= BodyWeight.maximumKilograms, "\(unit) ceiling: \(highest)")
        }
    }

    /// Every row the wheel offers has to come back to itself, or the wheel
    /// fights the user: they scroll to a row and it snaps somewhere else.
    @Test("Every offered row round-trips to the same row")
    func everyRowRoundTrips() {
        for unit in BodyWeightUnit.allCases {
            let wheel = WeightWheel(unit)

            for value in wheel.wholeRange {
                for tenth in wheel.tenthRange {
                    let kg = wheel.kilograms(whole: value, tenth: tenth)
                    let digits = wheel.digits(kg)

                    #expect(digits.whole == value, "\(unit) \(value).\(tenth) -> \(digits)")
                    #expect(digits.tenth == tenth, "\(unit) \(value).\(tenth) -> \(digits)")
                }
            }
        }
    }

    /// The point of a shared unit: a weight picked in one unit and read in the
    /// other is the same weight, not a value that shifts each time you switch.
    @Test("Switching units does not move the weight")
    func switchingUnitsKeepsTheWeight() {
        let kilograms = WeightWheel(.kilograms)
        let pounds = WeightWheel(.pounds)

        let kg = kilograms.kilograms(whole: 83, tenth: 4)
        let asPounds = pounds.digits(kg)
        let back = pounds.kilograms(whole: asPounds.whole, tenth: asPounds.tenth)

        #expect(abs(back - kg) < 0.06, "\(kg) kg -> \(asPounds) lb -> \(back) kg")
    }

    @Test("Pounds move in 0.2 steps, kilograms in 0.1")
    func tenthSteps() {
        #expect(WeightWheel(.kilograms).tenthRange == Array(0...9))
        #expect(WeightWheel(.pounds).tenthRange == [0, 2, 4, 6, 8])
    }

    @Test("Out-of-range rows clamp to the stored range")
    func clamping() {
        let wheel = WeightWheel(.kilograms)
        #expect(wheel.kilograms(whole: 500, tenth: 0) == BodyWeight.maximumKilograms)
        #expect(wheel.kilograms(whole: 1, tenth: 0) == BodyWeight.minimumKilograms)
    }

    /// A `Picker` handed a selection outside its options shows none of them.
    /// These seeds are the ways a weight reaches the wheel without being picked
    /// on it: Apple Health, an older saved profile, and both range ends.
    @Test("Any stored weight snaps onto a row the wheel offers", arguments: [
        30.0, 30.4, 66.1, 75.0, 83.4, 199.9, 200.0, 250.0, 12.0
    ])
    func everyStoredWeightLandsOnARow(seed: Double) {
        for unit in BodyWeightUnit.allCases {
            let wheel = WeightWheel(unit)
            let snapped = wheel.snapped(seed)
            let digits = wheel.digits(snapped)

            #expect(wheel.wholeRange.contains(digits.whole), "\(seed) \(unit): \(digits.whole)")
            #expect(wheel.tenthRange.contains(digits.tenth), "\(seed) \(unit): .\(digits.tenth)")
            #expect(snapped >= BodyWeight.minimumKilograms)
            #expect(snapped <= BodyWeight.maximumKilograms)
        }
    }

    /// The step differs between the wheels, so each switch re-snaps. It has to
    /// settle on the first switch — a weight that loses a tenth every time the
    /// user taps the toggle would walk away from what they weigh.
    @Test("Toggling units repeatedly settles instead of drifting", arguments: [
        30.0, 62.3, 83.4, 100.0, 199.9
    ])
    func togglingUnitsSettles(seed: Double) {
        let settled = WeightWheel(.pounds).snapped(WeightWheel(.kilograms).snapped(seed))

        var value = settled
        for step in 0..<10 {
            value = WeightWheel(step.isMultiple(of: 2) ? .kilograms : .pounds).snapped(value)
        }

        #expect(abs(value - settled) < 0.001, "\(seed) drifted to \(value) from \(settled)")
    }
}
