//
//  GoalPaceTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("GoalPace")
struct GoalPaceTests {
    @Test("Each goal offers its own paces, and Maintain offers none")
    func optionsPerGoal() {
        #expect(GoalPace.options(for: .cut) == [.gentle, .steady, .faster])
        #expect(GoalPace.options(for: .leanBulk) == [.slow, .steady])
        #expect(GoalPace.options(for: .maintain).isEmpty)
    }

    @Test("Maintain resolves to no pace, whatever was stored")
    func maintainHasNoPace() {
        #expect(GoalPace.resolved(nil, for: .maintain) == nil)
        #expect(GoalPace.resolved(.faster, for: .maintain) == nil)
        #expect(GoalPace.resolved(.steady, for: nil) == nil)
    }

    @Test("A missing pace, or one the goal does not offer, resolves to Steady")
    func fallsBackToSteady() {
        #expect(GoalPace.resolved(nil, for: .cut) == .steady)
        #expect(GoalPace.resolved(.gentle, for: .leanBulk) == .steady)
        #expect(GoalPace.resolved(.slow, for: .cut) == .steady)
    }

    @Test("A pace the goal offers is kept")
    func keepsValidPace() {
        #expect(GoalPace.resolved(.faster, for: .cut) == .faster)
        #expect(GoalPace.resolved(.slow, for: .leanBulk) == .slow)
    }

    @Test("Percent a week matches the presets")
    func percentPerWeek() {
        #expect(GoalPace.gentle.percentPerWeek(for: .cut) == 0.5)
        #expect(GoalPace.steady.percentPerWeek(for: .cut) == 0.75)
        #expect(GoalPace.faster.percentPerWeek(for: .cut) == 1.0)
        #expect(GoalPace.slow.percentPerWeek(for: .leanBulk) == 0.25)
        #expect(GoalPace.steady.percentPerWeek(for: .leanBulk) == 0.5)
        #expect(GoalPace.steady.percentPerWeek(for: .maintain) == 0)
    }

    @Test("Kilograms a week at 80 kg are signed: negative when losing")
    func signedKgPerWeek() {
        #expect(abs(GoalPace.steady.kgPerWeek(for: .cut, weightKg: 80) - -0.6) < 1e-9)
        #expect(abs(GoalPace.slow.kgPerWeek(for: .leanBulk, weightKg: 80) - 0.2) < 1e-9)
        #expect(GoalPace.steady.kgPerWeek(for: .maintain, weightKg: 80) == 0)
    }

    @Test("An unknown stored value reads as Steady")
    func unknownRawValueDecodesToSteady() throws {
        let data = Data(#"["steady", "zoom"]"#.utf8)
        let decoded = try JSONDecoder().decode([GoalPace].self, from: data)
        #expect(decoded == [.steady, .steady])
    }
}
