//
//  WeightPlan.swift
//  GymFuel
//

import Foundation

/// A corner of the plan line, for drawing.
struct WeightPlanPoint: Identifiable, Equatable, Sendable {
    let date: Date
    let weightKg: Double

    var id: Date { date }
}

/// The plan line: from where the plan started toward the goal weight, at the
/// plan's pace — `build-order.md` Step 4, *The rules*. Pure: no Firebase, no UI.
///
/// Worked out on read from what the profile saved when the plan started, so
/// nothing here is stored and editing targets never redraws it. It is straight
/// because the saved calorie target is fixed.
struct WeightPlan: Equatable, Sendable {
    let goal: GoalType
    /// Local midday of `planStartedOn` — the same x coordinate the trend uses.
    let startDate: Date
    let startWeightKg: Double
    /// Nil when maintaining.
    let goalWeightKg: Double?
    /// Below zero losing, above zero gaining, zero when the line is flat.
    let weeklyChangeKg: Double

    private static let secondsPerWeek: Double = 7 * 86_400

    /// The goal's pace on the start weight, so the line and the calorie target
    /// come from the same number.
    ///
    /// A loss is eased when the calorie floor lifted the target: the line never
    /// promises more than the maintenance estimate minus the floor leaves room
    /// for. Otherwise a small or older user eating exactly their target sits above
    /// the line from the first week (decided 19 September).
    static func weeklyChangeKg(
        goal: GoalType,
        startWeightKg: Double,
        maintenanceCalories: Double?,
        gender: Gender
    ) -> Double {
        let paced = startWeightKg * goal.weeklyPace
        guard paced < 0, let maintenanceCalories else { return paced }

        let dailyRoom = max(0, maintenanceCalories - SafetyLimits.calorieFloor(for: gender))
        return max(paced, -dailyRoom * 7 / MacroTargetCalculator.caloriesPerKg)
    }

    /// Where the line is on `date`, or nil before the plan started.
    ///
    /// It holds at the goal once it gets there, and stays flat at the start weight
    /// when the goal is not ahead of it — a Recalculate after reaching the goal
    /// must not make the line jump.
    func weightKg(on date: Date) -> Double? {
        guard date >= startDate else { return nil }
        guard let goalWeightKg, isHeadingToGoal else { return startWeightKg }

        let weeks = date.timeIntervalSince(startDate) / Self.secondsPerWeek
        let planned = startWeightKg + weeklyChangeKg * weeks
        return weeklyChangeKg < 0 ? max(planned, goalWeightKg) : min(planned, goalWeightKg)
    }

    /// When the line reaches the goal weight. Nil when it never moves, so no date
    /// is promised that the targets cannot deliver.
    var goalDate: Date? {
        guard let goalWeightKg, isHeadingToGoal else { return nil }

        let weeks = (goalWeightKg - startWeightKg) / weeklyChangeKg
        return startDate.addingTimeInterval(weeks * Self.secondsPerWeek)
    }

    /// The line's corners between two dates: where it enters the range, where it
    /// reaches the goal if that falls inside, and where it leaves.
    func points(from start: Date, through end: Date) -> [WeightPlanPoint] {
        let first = max(start, startDate)
        guard first < end else { return [] }

        var dates = [first]
        if let goalDate, goalDate > first, goalDate < end {
            dates.append(goalDate)
        }
        dates.append(end)

        return dates.compactMap { date in
            weightKg(on: date).map { WeightPlanPoint(date: date, weightKg: $0) }
        }
    }

    /// Whether the trend has got to the goal weight. Never while maintaining.
    ///
    /// Reaching it changes nothing by itself: the screen says so, and the user
    /// picks what comes next.
    func isGoalReached(trendKg: Double) -> Bool {
        guard let goalWeightKg else { return false }

        switch goal {
        case .cut: return trendKg <= goalWeightKg
        case .leanBulk: return trendKg >= goalWeightKg
        case .maintain: return false
        }
    }

    /// Whether the line moves at all: a goal weight on the side the pace heads.
    private var isHeadingToGoal: Bool {
        guard let goalWeightKg else { return false }
        return (goalWeightKg - startWeightKg) * weeklyChangeKg > 0
    }
}

extension WeightPlan {
    /// The plan the profile saved. Nil until a plan has started, and for Gain or
    /// Lose fat without a goal weight, which gives the line nowhere to go.
    init?(profile: UserProfile, timeZone: TimeZone = .current) {
        guard let key = profile.planStartedOn,
              let startDate = DateKey.date(from: key, timeZone: timeZone),
              let startWeightKg = profile.planStartWeightKg
        else { return nil }

        // The fallback `MacroTargetCalculator` uses, so the line and the targets
        // always read the same goal.
        let goal = profile.goalType ?? .defaultValue
        let goalWeightKg = goal == .maintain ? nil : profile.goalWeightKg
        guard goal == .maintain || goalWeightKg != nil else { return nil }

        self.init(
            goal: goal,
            startDate: startDate,
            startWeightKg: startWeightKg,
            goalWeightKg: goalWeightKg,
            weeklyChangeKg: Self.weeklyChangeKg(
                goal: goal,
                startWeightKg: startWeightKg,
                maintenanceCalories: profile.maintenanceCalories,
                gender: profile.gender
            )
        )
    }
}
