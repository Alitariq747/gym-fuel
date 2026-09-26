//
//  BodyHeightTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("HeightWheel")
struct HeightWheelTests {
    private let centimeters = HeightWheel(.centimeters)
    private let feetInches = HeightWheel(.feetInches)

    /// The feet rows are derived from the centimetre range, so a foot mark the
    /// range cannot reach is never offered. The hand-written `3...8` it replaces
    /// put an 8′ row on the wheel that could only snap back.
    @Test("Feet rows cover the centimetre range and nothing beyond it")
    func feetRangeIsDerived() {
        #expect(feetInches.feetRange == 3...7)
        #expect(centimeters.centimeterRange == 120...220)
    }

    /// Both ends of the range land mid-foot — 120 cm is 3′ 11″, 220 cm is 7′ 3″ —
    /// so those marks offer fewer inches than the twelve in between.
    @Test("Partial feet at each end offer only the inches that exist")
    func partialFeet() {
        #expect(feetInches.inchRange(atFeet: 3) == 11...11)
        #expect(feetInches.inchRange(atFeet: 5) == 0...11)
        #expect(feetInches.inchRange(atFeet: 7) == 0...3)
    }

    /// Every row has to come back to itself, or the wheel fights the user: they
    /// scroll to a row and it moves somewhere else.
    @Test("Every offered foot and inch row round-trips to the same row")
    func everyRowRoundTrips() {
        for feet in feetInches.feetRange {
            for inches in feetInches.inchRange(atFeet: feet) {
                let stored = feetInches.centimeters(feet: feet, inches: inches)
                let back = feetInches.feetInches(stored)

                #expect(back.feet == feet, "\(feet)′ \(inches)″ -> \(stored) cm -> \(back)")
                #expect(back.inches == inches, "\(feet)′ \(inches)″ -> \(stored) cm -> \(back)")
            }
        }
    }

    @Test("Every offered row stores a height inside the range")
    func everyRowStoresInRange() {
        for feet in feetInches.feetRange {
            for inches in feetInches.inchRange(atFeet: feet) {
                let stored = Double(feetInches.centimeters(feet: feet, inches: inches))

                #expect(stored >= BodyHeight.minimumCentimeters, "\(feet)′ \(inches)″ -> \(stored)")
                #expect(stored <= BodyHeight.maximumCentimeters, "\(feet)′ \(inches)″ -> \(stored)")
            }
        }
    }

    /// A `Picker` handed a selection outside its options shows none of them, so
    /// switching units must never land between rows.
    @Test("Every centimetre row maps onto a foot and inch row that is offered")
    func unitSwitchAlwaysLandsOnARow() {
        for value in centimeters.centimeterRange {
            let parts = feetInches.feetInches(value)

            #expect(feetInches.feetRange.contains(parts.feet), "\(value) cm -> \(parts.feet)′")
            #expect(
                feetInches.inchRange(atFeet: parts.feet).contains(parts.inches),
                "\(value) cm -> \(parts.feet)′ \(parts.inches)″ is not offered at that foot mark"
            )
        }
    }

    /// The bug this type replaces. `computedHeightCm` returned
    /// `totalInches * 2.54` without ever clamping, so an out-of-range wheel
    /// position was saved as-is.
    @Test("An out-of-range foot and inch height clamps instead of being stored")
    func outOfRangeClamps() {
        #expect(feetInches.centimeters(feet: 8, inches: 9) == 220)
        #expect(feetInches.centimeters(feet: 2, inches: 0) == 120)
    }

    @Test("Heights from outside the wheel clamp onto it", arguments: [80, 119, 120, 175, 220, 221, 300])
    func storedHeightsClamp(seed: Int) {
        #expect(centimeters.centimeterRange.contains(centimeters.clamped(seed)))

        let parts = feetInches.feetInches(seed)
        #expect(feetInches.inchRange(atFeet: parts.feet).contains(parts.inches), "\(seed) -> \(parts)")
    }

    @Test("Display strings")
    func display() {
        #expect(centimeters.displayString(175) == "175 cm")
        #expect(feetInches.displayString(175) == "5′ 9″")
        #expect(BodyHeightUnit.centimeters.shortLabel == "cm")
        #expect(BodyHeightUnit.feetInches.shortLabel == "ft/in")
    }
}
