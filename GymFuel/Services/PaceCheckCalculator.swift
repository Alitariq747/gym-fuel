//
//  PaceCheckCalculator.swift
//  GymFuel
//

import Foundation

/// What the pace check saw. Carried on every result that got far enough to
/// measure, so the check-in can say what happened in one sentence.
struct PaceReading: Equatable, Sendable {
    /// Best-fit pace over the window. **Signed: negative means losing.**
    let paceKgPerWeek: Double
    /// **Signed.** 0 for Maintain.
    let goalKgPerWeek: Double
    /// The smoothed weight today.
    let trendKg: Double
    let weighInCount: Int
    let windowDays: Int
    /// Context only — counted, never read for calories.
    let loggedDays: Int
}

enum PaceCheckResult: Equatable, Sendable {
    enum NotEnoughData: Equatable, Sendable {
        /// Too soon after the phase started or the last accept/reject.
        case waiting(daysLeft: Int)
        case tooFewWeighIns(count: Int)
        /// Readings bunched too close together to make a slope.
        case spanTooShort(days: Int)
    }

    case notEnoughData(NotEnoughData)
    /// The trend has reached the target weight. The check-in offers Maintain
    /// instead of a step.
    case targetReached(PaceReading)
    case onPace(PaceReading)
    /// Maintain: inside the band, or already heading back into it.
    case inBand(PaceReading)
    /// A step would have been suggested, but food was not logged on most days.
    case loggingGap(PaceReading)
    /// A step down was due, but the target is already at the floor.
    case atFloor(PaceReading)
    /// - `delta`: the change actually applied to today's target, after the floor.
    /// - `newAdjustment`: the phase's `calorieAdjustment` if the user accepts.
    case step(PaceReading, delta: Double, newCalories: Double, newAdjustment: Double)

    var reading: PaceReading? {
        switch self {
        case .notEnoughData:
            return nil
        case .targetReached(let reading), .onPace(let reading), .inBand(let reading),
             .loggingGap(let reading), .atFloor(let reading):
            return reading
        case .step(let reading, _, _, _):
            return reading
        }
    }
}

/// The weekly pace check: *is weight moving at the pace the user chose?*
///
/// Pure, no I/O. Every value is a starting value from `build-order.md` Step 4,
/// "The pace check" — none is a claim shown to the user. It reads the weigh-ins
/// and whether days were logged; it never reads calories eaten.
struct PaceCheckCalculator {
    struct Input {
        /// Raw weigh-ins, any order. Older ones are fine — they settle the trend.
        let weighIns: [WeighIn]
        let phase: Phase
        /// Days with at least one succeeded log entry.
        let loggedDayKeys: Set<String>
        let todayKey: String
        /// `MacroTargetCalculator.CalorieBounds` for the profile today.
        let baseCalories: Double
        let floorCalories: Double
    }

    static let minimumDaysSinceAnchor = 14
    static let maximumWindowDays = 21
    static let minimumWeighIns = 6
    static let minimumSpanDays = 10
    /// ±50 % of goal pace counts as on pace.
    static let onPaceTolerance = 0.5
    static let stepCalories: Double = 100
    static let maintainBandKg = 0.5
    /// Logged on most days: 5 in 7.
    static let loggedDaysPerWeek = 5

    /// Floating-point slack so the ±50 % edges count as on pace.
    private static let epsilon = 1e-9

    private let trendCalculator: WeightTrendCalculator

    init(trendCalculator: WeightTrendCalculator = WeightTrendCalculator()) {
        self.trendCalculator = trendCalculator
    }

    func evaluate(_ input: Input, timeZone: TimeZone = .current) -> PaceCheckResult {
        let calendar = DateKey.calendar(timeZone: timeZone)
        let phase = input.phase

        // Whole days between keys, from the calendar — date keys, not timestamps,
        // so a DST change or a late-night weigh-in cannot move a 14-day rule.
        func days(from startKey: String, to endKey: String) -> Int? {
            guard let start = DateKey.date(from: startKey, timeZone: timeZone),
                  let end = DateKey.date(from: endKey, timeZone: timeZone)
            else { return nil }
            return calendar.dateComponents([.day], from: start, to: end).day
        }

        // 1. Wait 14 days after the phase started or the last accept/reject.
        let anchorKey = max(phase.startDateKey, phase.lastStepDecisionDateKey ?? "")
        guard let daysSinceAnchor = days(from: anchorKey, to: input.todayKey) else {
            return .notEnoughData(.waiting(daysLeft: Self.minimumDaysSinceAnchor))
        }
        guard daysSinceAnchor >= Self.minimumDaysSinceAnchor else {
            return .notEnoughData(.waiting(daysLeft: Self.minimumDaysSinceAnchor - max(daysSinceAnchor, 0)))
        }

        // 2. The window: the last 14–21 days, never reaching back to the anchor.
        let windowDays = min(Self.maximumWindowDays, daysSinceAnchor)
        guard let today = DateKey.date(from: input.todayKey, timeZone: timeZone),
              let windowStart = calendar.date(byAdding: .day, value: -(windowDays - 1), to: today)
        else {
            return .notEnoughData(.waiting(daysLeft: Self.minimumDaysSinceAnchor))
        }
        let windowStartKey = DateKey.key(for: windowStart, timeZone: timeZone)

        // One reading per day, last occurrence wins — as in `WeightTrendCalculator`.
        var byDay: [String: WeighIn] = [:]
        for weighIn in input.weighIns where DateKey.date(from: weighIn.dateKey, timeZone: timeZone) != nil {
            byDay[weighIn.dateKey] = weighIn
        }
        let window = byDay.values
            .filter { $0.dateKey >= windowStartKey && $0.dateKey <= input.todayKey }
            .sorted { $0.dateKey < $1.dateKey }

        guard window.count >= Self.minimumWeighIns else {
            return .notEnoughData(.tooFewWeighIns(count: window.count))
        }
        let last = window[window.count - 1]
        let span = days(from: window[0].dateKey, to: last.dateKey) ?? 0
        guard span >= Self.minimumSpanDays else {
            return .notEnoughData(.spanTooShort(days: span))
        }

        // 3. Pace: least-squares slope over real day offsets, so a gap is a gap
        //    rather than a missing sample. Trend endpoints lag at the start of a
        //    phase; a fitted line through the raw readings does not.
        let points: [(x: Double, y: Double)] = window.compactMap { weighIn in
            days(from: windowStartKey, to: weighIn.dateKey).map { (Double($0), weighIn.weightKg) }
        }
        let count = Double(points.count)
        let meanX = points.reduce(0) { $0 + $1.x } / count
        let meanY = points.reduce(0) { $0 + $1.y } / count
        let sxx = points.reduce(0) { $0 + ($1.x - meanX) * ($1.x - meanX) }
        let sxy = points.reduce(0) { $0 + ($1.x - meanX) * ($1.y - meanY) }
        let paceKgPerWeek = sxx > 0 ? (sxy / sxx) * 7 : 0

        let throughToday = byDay.values.filter { $0.dateKey <= input.todayKey }
        let trendKg = trendCalculator.series(from: Array(throughToday), timeZone: timeZone).latest?.trendKg
            ?? last.weightKg

        let loggedDays = input.loggedDayKeys
            .filter { $0 >= windowStartKey && $0 <= input.todayKey }
            .count

        let reading = PaceReading(
            paceKgPerWeek: paceKgPerWeek,
            goalKgPerWeek: phase.goalKgPerWeek,
            trendKg: trendKg,
            weighInCount: window.count,
            windowDays: windowDays,
            loggedDays: loggedDays
        )

        // 4. Target weight reached — by the trend, not a single weigh-in.
        if let target = phase.targetWeightKg {
            switch phase.goalType {
            case .cut where trendKg <= target:
                return .targetReached(reading)
            case .leanBulk where trendKg >= target:
                return .targetReached(reading)
            default:
                break
            }
        }

        // 5. Which way, if any.
        let delta: Double
        switch phase.goalType {
        case .maintain:
            let offset = trendKg - phase.startWeightKg
            if abs(offset) <= Self.maintainBandKg + Self.epsilon {
                return .inBand(reading)
            }
            let headingBack = (offset > 0 && paceKgPerWeek < 0) || (offset < 0 && paceKgPerWeek > 0)
            if headingBack {
                return .inBand(reading)
            }
            delta = offset > 0 ? -Self.stepCalories : Self.stepCalories

        case .cut, .leanBulk:
            let goal = phase.goalKgPerWeek
            guard goal != 0 else { return .onPace(reading) }

            // Negative ratio means the wrong way, which is "too slow" too.
            let ratio = paceKgPerWeek / goal
            let slowest = 1 - Self.onPaceTolerance - Self.epsilon
            let fastest = 1 + Self.onPaceTolerance + Self.epsilon
            if ratio >= slowest && ratio <= fastest {
                return .onPace(reading)
            }
            let towardGoal = phase.goalType == .cut ? -Self.stepCalories : Self.stepCalories
            delta = ratio < slowest ? towardGoal : -towardGoal
        }

        // 6. If the target isn't being eaten, moving it helps nobody.
        let requiredLoggedDays = (windowDays * Self.loggedDaysPerWeek + 6) / 7
        guard loggedDays >= requiredLoggedDays else {
            return .loggingGap(reading)
        }

        // 7. The floor. An adjustment below `floor − base` has no effect on the
        //    target, so the step starts from there: a step up from a floored
        //    target moves it, and a step down never digs a hole below the floor.
        let effectiveAdjustment = max(phase.calorieAdjustment, input.floorCalories - input.baseCalories)
        let newAdjustment = max(effectiveAdjustment + delta, input.floorCalories - input.baseCalories)
        let currentCalories = max(input.baseCalories + phase.calorieAdjustment, input.floorCalories).rounded()
        let newCalories = max(input.baseCalories + newAdjustment, input.floorCalories).rounded()

        if delta < 0 && newCalories >= currentCalories {
            return .atFloor(reading)
        }

        return .step(
            reading,
            delta: newCalories - currentCalories,
            newCalories: newCalories,
            newAdjustment: newAdjustment
        )
    }
}
