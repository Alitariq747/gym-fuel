//
//  TodaySnapshotTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("Today snapshot")
struct TodaySnapshotTests {
    private let target = Macros(calories: 2400, protein: 150, carbs: 260, fat: 80)

    /// London, so 25 October 2026 is a 25-hour day when the clocks go back.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }

    private func date(_ day: Int, hour: Int = 12, minute: Int = 0) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute)))
    }

    private func snapshot(eaten calories: Double, logged: Int = 1, estimate: Bool = true) throws -> TodaySnapshot {
        TodaySnapshot(
            day: calendar.startOfDay(for: try date(3)),
            target: target,
            eaten: Macros(calories: calories, protein: 80, carbs: 130, fat: 50),
            loggedCount: logged,
            hasEstimate: estimate
        )
    }

    private func entry(
        _ status: LogEntryStatus = .succeeded,
        macros: Macros? = Macros(calories: 500, protein: 30, carbs: 50, fat: 20),
        breakdown: MealBreakdown? = nil,
        provenance: MealProvenance? = nil
    ) throws -> LogEntry {
        LogEntry(
            userId: "u",
            status: status,
            loggedAt: try date(3),
            title: "meal",
            rawInput: "rice and stew",
            feedback: status == .analyzing ? nil : LogEntryFeedback(
                explanation: "",
                macros: macros,
                breakdown: breakdown,
                macrosProvenance: provenance
            )
        )
    }

    private func built(_ entries: [LogEntry]) throws -> TodaySnapshot {
        TodaySnapshot(day: try date(3, hour: 21), target: target, eaten: .zero, entries: entries, calendar: calendar)
    }

    // MARK: - State

    @Test func nothingLoggedIsANewDay() throws {
        #expect(try snapshot(eaten: 0, logged: 0, estimate: false).state == .newDay)
    }

    @Test func underTargetIsNormal() throws {
        let snapshot = try snapshot(eaten: 1380)
        #expect(snapshot.state == .normal)
        #expect(snapshot.caloriesLeft == 1020)
    }

    @Test func exactlyOnTargetIsNormalWithNothingLeft() throws {
        let snapshot = try snapshot(eaten: 2400)
        #expect(snapshot.state == .normal)
        #expect(snapshot.caloriesLeft == 0)
    }

    @Test func overTargetIsOver() throws {
        let snapshot = try snapshot(eaten: 2520)
        #expect(snapshot.state == .over)
        #expect(snapshot.caloriesLeft == -120)
    }

    /// The Day card rounds the difference, so 0.4 over reads as 0 left there too.
    @Test func lessThanHalfACalorieOverRoundsToNothingLeft() throws {
        let snapshot = try snapshot(eaten: 2400.4)
        #expect(snapshot.state == .normal)
        #expect(snapshot.caloriesLeft == 0)
    }

    /// A settled meal with no calories, black coffee say, is still something logged.
    @Test func aZeroCalorieMealIsNotANewDay() throws {
        #expect(try snapshot(eaten: 0, logged: 1, estimate: false).state == .normal)
    }

    // MARK: - Ring

    @Test func theRingFillsWithWhatHasBeenEaten() throws {
        #expect(try snapshot(eaten: 1380).calorieProgress == 0.575)
    }

    @Test func theRingStopsAtFullWhenOver() throws {
        #expect(try snapshot(eaten: 2520).calorieProgress == 1)
    }

    @Test func theRingIsEmptyOnANewDay() throws {
        let rolled = try snapshot(eaten: 2520).rolledOver(to: try date(4), calendar: calendar)
        #expect(rolled.calorieProgress == 0)
    }

    // MARK: - Rollover

    @Test func theSameDayIsShownUnchanged() throws {
        let snapshot = try snapshot(eaten: 1380)
        #expect(snapshot.rolledOver(to: try date(3, hour: 23, minute: 59), calendar: calendar) == snapshot)
    }

    @Test func anEarlierDayBecomesAFreshDayWithTheSameTarget() throws {
        let rolled = try snapshot(eaten: 2520).rolledOver(to: try date(4, hour: 0), calendar: calendar)

        #expect(rolled.day == calendar.startOfDay(for: try date(4)))
        #expect(rolled.target == target)
        #expect(rolled.eaten == .zero)
        #expect(rolled.loggedCount == 0)
        #expect(rolled.hasEstimate == false)
        #expect(rolled.state == .newDay)
        #expect(rolled.caloriesLeft == 2400)
    }

    @Test func nextMidnightIsTheStartOfTomorrow() throws {
        let midnight = TodaySnapshot.nextMidnight(after: try date(3, hour: 21, minute: 30), calendar: calendar)
        #expect(midnight == calendar.startOfDay(for: try date(4)))
    }

    /// A fixed 24 hours from the start of 25 October lands at 23:00 the same day.
    @Test func nextMidnightHoldsOnTheDayTheClocksGoBack() throws {
        let midnight = TodaySnapshot.nextMidnight(after: try date(25, hour: 12), calendar: calendar)
        let parts = calendar.dateComponents([.day, .hour, .minute], from: midnight)

        #expect(parts.day == 26)
        #expect(parts.hour == 0)
        #expect(parts.minute == 0)
    }

    // MARK: - Building from entries

    @Test func onlySettledMealsCount() throws {
        let snapshot = try built([
            entry(),
            entry(.analyzing, macros: nil),
            entry(.failed, macros: nil)
        ])
        #expect(snapshot.loggedCount == 1)
    }

    @Test func aDayOfOnlyUnfinishedMealsIsStillANewDay() throws {
        let snapshot = try built([entry(.analyzing, macros: nil)])
        #expect(snapshot.state == .newDay)
        #expect(snapshot.hasEstimate == false)
    }

    @Test func oneEstimatedMealTurnsTheDottedRuleOn() throws {
        let snapshot = try built([
            entry(provenance: .reference),
            entry(provenance: .estimated)
        ])
        #expect(snapshot.hasEstimate)
    }

    @Test func referenceAndTypedTotalsLeaveTheDottedRuleOff() throws {
        let snapshot = try built([
            entry(provenance: .reference),
            entry(provenance: .userTotal)
        ])
        #expect(snapshot.hasEstimate == false)
    }

    /// The breakdown decides, as on the entry screen: the sample mixes a label
    /// value with estimates, so it stays an estimate whatever the meal-level field says.
    @Test func aBreakdownOverridesTheMealLevelProvenance() throws {
        let snapshot = try built([entry(breakdown: MealFixtures.sampleBreakdown, provenance: .reference)])
        #expect(snapshot.hasEstimate)
    }

    @Test func aMissingProvenanceReadsAsAnEstimate() throws {
        #expect(try built([entry()]).hasEstimate)
    }

    @Test func theDayIsStoredAsItsStart() throws {
        #expect(try built([]).day == calendar.startOfDay(for: try date(3)))
    }

    // MARK: - Today's note

    private func note(
        day: Int = 3,
        isLoaded: Bool = true,
        target: Macros? = Macros(calories: 2400, protein: 150, carbs: 260, fat: 80),
        now: Date
    ) throws -> TodaySnapshot? {
        let timeline = DayTimeline(date: try date(day), entries: [try entry()], calendar: calendar)
        let eaten = Macros(calories: 500, protein: 30, carbs: 50, fat: 20)
        return TodaySnapshot(today: timeline, isLoaded: isLoaded, target: target, eaten: eaten, now: now, calendar: calendar)
    }

    @Test func noNoteBeforeTodaysEntriesArrive() throws {
        #expect(try note(isLoaded: false, now: try date(3, hour: 21)) == nil)
    }

    @Test func noNoteWithoutASavedTarget() throws {
        #expect(try note(target: nil, now: try date(3, hour: 21)) == nil)
    }

    @Test func noNoteWhileBrowsingAnEarlierDay() throws {
        #expect(try note(day: 2, now: try date(3, hour: 21)) == nil)
    }

    /// The app left open past midnight still shows yesterday until it reloads.
    @Test func noNoteJustAfterMidnightForTheOldDay() throws {
        #expect(try note(day: 3, now: try date(4, hour: 0, minute: 1)) == nil)
    }

    @Test func aLoadedTodayGivesTheFullNote() throws {
        let snapshot = try #require(try note(now: try date(3, hour: 21)))

        #expect(snapshot.day == calendar.startOfDay(for: try date(3)))
        #expect(snapshot.target == target)
        #expect(snapshot.eaten.calories == 500)
        #expect(snapshot.loggedCount == 1)
        #expect(snapshot.state == .normal)
    }

    // MARK: - Saving

    @Test func survivesARoundTrip() throws {
        let snapshot = try snapshot(eaten: 1380.6)
        let data = try JSONEncoder().encode(snapshot)
        #expect(try JSONDecoder().decode(TodaySnapshot.self, from: data) == snapshot)
    }
}
