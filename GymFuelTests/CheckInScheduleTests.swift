//
//  CheckInScheduleTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// When a weekly check-in is due, `build-order.md` Step 4 decision 3.
///
/// Days are offsets from 1 September 2026 in UTC, so `day(7)` is 8 September.
@Suite("CheckInSchedule")
struct CheckInScheduleTests {
    private let utc = TimeZone(identifier: "UTC")!

    private func day(_ offset: Int) -> String {
        let calendar = DateKey.calendar(timeZone: utc)
        let base = DateKey.date(from: "2026-09-01", timeZone: utc)!
        return DateKey.key(for: calendar.date(byAdding: .day, value: offset, to: base)!, timeZone: utc)
    }

    private func phase(start: String) -> Phase {
        Phase(
            startDateKey: start,
            goalType: .cut,
            goalPace: .gentle,
            pacePercentPerWeek: 0.5,
            startWeightKg: 83,
            targetWeightKg: nil,
            startTargets: .zero,
            calorieAdjustment: 0,
            lastStepDecisionDateKey: nil,
            startedAt: Date(timeIntervalSince1970: 0)
        )
    }

    private func record(due: String, phaseStart: String) -> CheckIn {
        CheckIn(
            dueDateKey: due,
            phaseStartDateKey: phaseStart,
            decision: .onPace,
            response: .acknowledged,
            paceKgPerWeek: nil,
            goalKgPerWeek: nil,
            weighInCount: nil,
            windowDays: nil,
            loggedDays: 0,
            averageLoggedCalories: 0,
            suggestedDelta: nil,
            targetsBefore: .zero,
            targetsAfter: .zero,
            completedDateKey: due,
            completedAt: Date(timeIntervalSince1970: 0)
        )
    }

    private func schedule(start: String, today: String, latest: CheckIn? = nil) -> CheckInSchedule {
        CheckInSchedule(phase: phase(start: start), latest: latest, todayKey: today, timeZone: utc)
    }

    @Test func dayBeforeTheFirstIsNotOpen() {
        let schedule = schedule(start: day(0), today: day(6))
        #expect(schedule.openDueDateKey == nil)
        #expect(schedule.nextDueDateKey == day(7))
    }

    @Test func dayOfTheFirstIsOpen() {
        let schedule = schedule(start: day(0), today: day(7))
        #expect(schedule.openDueDateKey == day(7))
        #expect(schedule.nextDueDateKey == day(7))
    }

    @Test func missedWeeksCollapseIntoTheLatest() {
        #expect(schedule(start: day(0), today: day(20)).openDueDateKey == day(14))
    }

    @Test func answeredCheckInIsNotOpen() {
        let schedule = schedule(start: day(0), today: day(20), latest: record(due: day(14), phaseStart: day(0)))
        #expect(schedule.openDueDateKey == nil)
        #expect(schedule.nextDueDateKey == day(21))
    }

    @Test func dueDateCrossesMonthEnd() {
        #expect(schedule(start: "2027-01-28", today: "2027-02-04").openDueDateKey == "2027-02-04")
    }

    @Test func dueDateLandsOnLeapDay() {
        #expect(schedule(start: "2028-02-22", today: "2028-02-29").openDueDateKey == "2028-02-29")
    }

    @Test func recordFromAnOlderPhaseDoesNotCount() {
        let schedule = schedule(start: day(7), today: day(14), latest: record(due: day(14), phaseStart: day(0)))
        #expect(schedule.openDueDateKey == day(14))
    }

    @Test func malformedKeysOpenNothing() {
        let schedule = schedule(start: "2026-02-30", today: day(7))
        #expect(schedule.openDueDateKey == nil)
        #expect(schedule.nextDueDateKey == nil)
    }
}
