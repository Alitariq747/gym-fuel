//
//  UserProfileTargetsTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("Saved targets")
struct UserProfileTargetsTests {
    private let targets = MacroTargets(
        macros: Macros(calories: 2_000, protein: 130, carbs: 224, fat: 65),
        maintenanceCalories: 2_470
    )

    /// 85 kg, 180 cm, 30, losing fat, with nothing saved yet.
    private let sample = UserProfile(
        name: "",
        heightCm: 180,
        age: 30,
        weightKg: 85,
        goalType: .cut,
        activityLevel: .mostlySitting,
        isOnboardingComplete: true,
        gender: .male
    )

    /// Midday on the local day `key` names.
    private func day(_ key: String) throws -> Date {
        try #require(DateKey.date(from: key))
    }

    @Test("Setting targets saves the numbers, the day and the weight")
    func setTargetsStamps() throws {
        var profile = sample
        profile.setTargets(targets, on: try day("2026-09-03"))

        #expect(profile.savedTargets == targets.macros)
        #expect(profile.maintenanceCalories == 2_470)
        #expect(profile.targetsSetOn == "2026-09-03")
        #expect(profile.targetsSetAtWeightKg == 85)
    }

    @Test("Setting targets again replaces the old ones")
    func setTargetsOverwrites() throws {
        var profile = sample
        profile.setTargets(targets, on: try day("2026-09-03"))

        profile.weightKg = 80
        let newer = MacroTargets(
            macros: Macros(calories: 1_900, protein: 128, carbs: 205, fat: 64),
            maintenanceCalories: 2_380
        )
        profile.setTargets(newer, on: try day("2026-10-01"))

        #expect(profile.savedTargets == newer.macros)
        #expect(profile.maintenanceCalories == 2_380)
        #expect(profile.targetsSetOn == "2026-10-01")
        #expect(profile.targetsSetAtWeightKg == 80)
    }

    @Test("Starting the plan saves the day and the weight")
    func startPlanStamps() throws {
        var profile = sample
        profile.startPlan(on: try day("2026-09-03"))

        #expect(profile.planStartedOn == "2026-09-03")
        #expect(profile.planStartWeightKg == 85)
    }

    /// The rule Step 4c exists for: weigh-ins update `weightKg` and nothing else.
    @Test("A weigh-in changes the weight and leaves the saved targets alone")
    func weighInLeavesTargets() throws {
        var profile = sample
        profile.setTargets(targets, on: try day("2026-09-03"))

        profile.weightKg = 80

        #expect(profile.savedTargets == targets.macros)
        #expect(profile.targetsSetAtWeightKg == 85)
    }

    @Test("There are no saved targets until all four numbers exist")
    func savedTargetsNeedAllFour() throws {
        var profile = sample
        #expect(profile.savedTargets == nil)

        profile.setTargets(targets, on: try day("2026-09-03"))
        profile.targetFatG = nil
        #expect(profile.savedTargets == nil)
    }

    /// A field left out of `CodingKeys` is dropped silently rather than failing
    /// to compile, so this is the only thing that catches it.
    @Test("Every saved field survives encoding and decoding")
    func roundTrip() throws {
        var profile = sample
        profile.setTargets(targets, on: try day("2026-09-03"))
        profile.startPlan(on: try day("2026-09-03"))

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)

        #expect(decoded == profile)
    }

    @Test("A profile saved before targets were stored decodes with none")
    func olderProfileDecodes() throws {
        // Nil fields are left out when encoding, so this is the shape of a
        // document written before Step 4c.
        let data = try JSONEncoder().encode(sample)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)

        #expect(decoded.savedTargets == nil)
        #expect(decoded.maintenanceCalories == nil)
        #expect(decoded.targetsSetOn == nil)
        #expect(decoded.planStartedOn == nil)
    }
}
