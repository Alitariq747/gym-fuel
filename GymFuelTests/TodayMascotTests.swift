//
//  TodayMascotTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("Today widget mascot")
struct TodayMascotTests {

    private func snapshot(eaten calories: Double, logged: Int) -> TodaySnapshot {
        TodaySnapshot(
            day: Date(timeIntervalSinceReferenceDate: 0),
            target: Macros(calories: 2400, protein: 150, carbs: 260, fat: 80),
            eaten: Macros(calories: calories, protein: 80, carbs: 130, fat: 50),
            loggedCount: logged,
            hasEstimate: true
        )
    }

    @Test func noNoteHoldsThePhone() {
        #expect(PlateMascot.Move.today(nil) == .phone)
    }

    @Test func nothingLoggedWaves() {
        #expect(PlateMascot.Move.today(snapshot(eaten: 0, logged: 0)) == .wave)
    }

    @Test func aLoggedDayWrites() {
        #expect(PlateMascot.Move.today(snapshot(eaten: 1380, logged: 2)) == .write)
    }

    /// Rule 9: no reaction to how the day is going.
    @Test func overTargetStillWrites() {
        #expect(PlateMascot.Move.today(snapshot(eaten: 2520, logged: 3)) == .write)
    }

    @Test func aNewDayAtMidnightWaves() {
        let rolled = snapshot(eaten: 2520, logged: 3).rolledOver(to: Date(timeIntervalSinceReferenceDate: 86_400 * 2))
        #expect(PlateMascot.Move.today(rolled) == .wave)
    }
}
