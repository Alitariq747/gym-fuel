//
//  TodayCopyTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("Today copy")
struct TodayCopyTests {

    private func snapshot(eaten calories: Double, logged: Int = 1) -> TodaySnapshot {
        TodaySnapshot(
            day: Date(timeIntervalSinceReferenceDate: 0),
            target: Macros(calories: 2400, protein: 150, carbs: 260, fat: 80),
            eaten: Macros(calories: calories, protein: 80, carbs: 130, fat: 50),
            loggedCount: logged,
            hasEstimate: true
        )
    }

    @Test func aNormalDay() {
        let day = snapshot(eaten: 1380)
        #expect(TodayCopy.number(day) == "1,020")
        #expect(TodayCopy.label(day) == "kcal left")
        #expect(TodayCopy.progress(day) == "1,380 of 2,400")
        #expect(TodayCopy.inline(day) == "1,020 kcal left")
    }

    @Test func aNewDay() {
        let day = snapshot(eaten: 0, logged: 0)
        #expect(TodayCopy.number(day) == "2,400")
        #expect(TodayCopy.label(day) == "kcal left")
        #expect(TodayCopy.progress(day) == "the whole day")
        #expect(TodayCopy.inline(day) == "2,400 kcal left")
    }

    @Test func anOverDayShowsHowFarOverWithoutASign() {
        let day = snapshot(eaten: 2520)
        #expect(TodayCopy.number(day) == "120")
        #expect(TodayCopy.label(day) == "kcal over")
        #expect(TodayCopy.progress(day) == "2,520 of 2,400")
        #expect(TodayCopy.inline(day) == "120 kcal over")
    }

    @Test func theCircleSaysLeftOrOverWithoutKcal() {
        #expect(TodayCopy.shortLabel(snapshot(eaten: 1380)) == "left")
        #expect(TodayCopy.shortLabel(snapshot(eaten: 2400)) == "left")
        #expect(TodayCopy.shortLabel(snapshot(eaten: 2520)) == "over")
    }

    @Test func noNoteAsksToOpenTheApp() {
        #expect(TodayCopy.inline(nil) == "Open to see today")
    }

    /// As on the Day card: a logged meal with no calories still reads as the whole day.
    @Test func aZeroCalorieMealStillReadsAsTheWholeDay() {
        #expect(TodayCopy.progress(snapshot(eaten: 0, logged: 1)) == "the whole day")
    }

    @Test func voiceOverSaysTheDayCardsSentenceAndTheEstimate() {
        #expect(TodayCopy.spoken(snapshot(eaten: 1380)) == "1,020 calories left, estimated, 1,380 of 2,400")
        #expect(TodayCopy.spoken(snapshot(eaten: 2520)) == "120 calories over, estimated, 2,520 of 2,400")
    }

    /// A new day is the saved target, so there is no estimate to mention.
    @Test func voiceOverOnANewDayHasNoEstimate() {
        let newDay = snapshot(eaten: 1380).rolledOver(to: Date(timeIntervalSinceReferenceDate: 86_400 * 2))
        #expect(TodayCopy.spoken(newDay) == "2,400 calories left, the whole day")
    }

    @Test func numbersAreRoundedOnceForDisplay() {
        let day = snapshot(eaten: 1379.6)
        #expect(TodayCopy.number(day) == "1,020")
        #expect(TodayCopy.progress(day) == "1,380 of 2,400")
    }
}
