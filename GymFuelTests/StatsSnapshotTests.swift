//
//  StatsSnapshotTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

/// The Week screen's chart and its legend read these, and the point of putting
/// them on the model was that the two cannot disagree: a day drawn ochre must be
/// one of the days counted as outside.
@Suite("StatsSnapshot")
struct StatsSnapshotTests {

    private func day(_ offset: Int, calories: Double, target: Double? = 2400) -> DailyStatsSnapshot {
        DailyStatsSnapshot(
            date: Date(timeIntervalSince1970: 1_757_000_000 + Double(offset) * 86_400),
            caloriesEaten: calories,
            protein: 0,
            carbs: 0,
            fat: 0,
            targetCalories: target,
            targetProtein: 165,
            targetCarbs: 240,
            targetFat: 80
        )
    }

    private func snapshot(_ calories: [Double]) -> StatsSnapshot {
        let days = calories.enumerated().map { day($0.offset, calories: $0.element) }
        var snapshot = StatsSnapshot.empty
        snapshot.dailyStats = days
        snapshot.calorieTargetDays = days.filter(\.isWithinCalorieRange).count
        return snapshot
    }

    @Test("A day with nothing on it is neither in range nor outside")
    func emptyDayIsNeither() {
        let empty = day(0, calories: 0)

        #expect(!empty.hasFood)
        #expect(!empty.isWithinCalorieRange)
    }

    @Test("In range is within 15% either side of target")
    func rangeBoundaries() {
        #expect(day(0, calories: 2400).isWithinCalorieRange)
        #expect(day(0, calories: 2040).isWithinCalorieRange)   // exactly -15%
        #expect(day(0, calories: 2760).isWithinCalorieRange)   // exactly +15%
        #expect(!day(0, calories: 2039).isWithinCalorieRange)
        #expect(!day(0, calories: 2761).isWithinCalorieRange)
    }

    @Test("A day with no target cannot be in range")
    func noTargetIsNeverInRange() {
        #expect(!day(0, calories: 2400, target: nil).isWithinCalorieRange)
    }

    @Test("In range and outside together account for every day with food")
    func countsPartitionTheLoggedDays() {
        // Four in range, two outside, one empty.
        let week = snapshot([2310, 2480, 2395, 2520, 2900, 1500, 0])

        #expect(week.daysWithFood == 6)
        #expect(week.calorieTargetDays == 4)
        #expect(week.daysOutsideCalorieRange == 2)
        #expect(week.calorieTargetDays + week.daysOutsideCalorieRange == week.daysWithFood)
    }

    @Test("An empty week counts nothing and offers no averages")
    func emptyWeek() {
        let week = snapshot([0, 0, 0, 0, 0, 0, 0])

        #expect(week.daysWithFood == 0)
        #expect(week.daysOutsideCalorieRange == 0)
        #expect(!week.hasEnoughDaysForAverages)
    }

    @Test("Averages wait for the fourth day with food")
    func averagesThreshold() {
        #expect(!snapshot([2400, 2400, 2400, 0, 0, 0, 0]).hasEnoughDaysForAverages)
        #expect(snapshot([2400, 2400, 2400, 2400, 0, 0, 0]).hasEnoughDaysForAverages)
    }
}
