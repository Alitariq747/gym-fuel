//
//  TargetsCopyTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// These assertions deliberately avoid whole formatted strings: both the number
/// and the month come from the device locale, so "Set at 83 kg on 19 Sep" is only
/// the English form of what `setAt` returns. What is worth pinning is the
/// rounding, the unit conversion, the nil cases, and that the estimate copy never
/// claims to measure a burn.
@Suite("TargetsCopy")
struct TargetsCopyTests {

    @Test("Set at reads back the kilogram it was given")
    func setAtInKilograms() throws {
        let line = try #require(TargetsCopy.setAt(weightKg: 83, on: "2026-09-19", unit: .kilograms))

        #expect(line.hasPrefix("Set at"))
        #expect(line.contains("83"))
        #expect(line.contains("kg"))
        #expect(line.contains("19"))
    }

    @Test("Set at converts to pounds for a pounds user")
    func setAtInPounds() throws {
        let line = try #require(TargetsCopy.setAt(weightKg: 83, on: "2026-09-19", unit: .pounds))

        // 83 kg is 182.98 lb, which rounds to 183 rather than truncating to 182.
        #expect(line.contains("183"))
        #expect(line.contains("lbs"))
    }

    @Test("Set at shows a whole weight, not the stored two decimal places")
    func setAtRoundsToWholeUnits() throws {
        let line = try #require(TargetsCopy.setAt(weightKg: 83.64, on: "2026-09-19", unit: .kilograms))

        #expect(line.contains("84"))
        #expect(!line.contains("83"))
    }

    @Test("Set at needs both a weight and a day that exists")
    func setAtNeedsBoth() {
        #expect(TargetsCopy.setAt(weightKg: nil, on: "2026-09-19", unit: .kilograms) == nil)
        #expect(TargetsCopy.setAt(weightKg: 83, on: nil, unit: .kilograms) == nil)
        #expect(TargetsCopy.setAt(weightKg: 83, on: "", unit: .kilograms) == nil)
        // `DateKey.date(from:)` rejects a day that does not exist rather than
        // rolling it forward into March, and the copy follows it.
        #expect(TargetsCopy.setAt(weightKg: 83, on: "2026-02-30", unit: .kilograms) == nil)
    }

    @Test("The maintenance estimate shows no decimals")
    func maintenanceValueDropsDecimals() {
        #expect(TargetsCopy.maintenanceValue(2_420).contains("420"))
        #expect(TargetsCopy.maintenanceValue(2_420.4) == TargetsCopy.maintenanceValue(2_420))
        #expect(TargetsCopy.maintenanceValue(2_419.6) == TargetsCopy.maintenanceValue(2_420))
    }

    /// The App Store 1.4.1 failure mode, as a test: a number that claims to
    /// measure what this person burns needs validation the app does not have.
    @Test("The estimate copy never calls it a burn")
    func estimateNeverSaysBurn() {
        let copy = [
            TargetsCopy.maintenanceLabel,
            TargetsCopy.maintenancePrefix,
            TargetsCopy.maintenanceSuffix,
            TargetsCopy.startingEstimate,
        ]
        .joined(separator: " ")
        .lowercased()

        #expect(!copy.contains("burn"))
        #expect(copy.contains("estimate"))
    }
}
