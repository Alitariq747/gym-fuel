//
//  CheckInCopy.swift
//  GymFuel
//

import Foundation

/// The one sentence a check-in says, rebuilt from what the pace check saw.
///
/// Pure, so the wording is testable. `build-order.md` Step 4: the check-in
/// explains itself in one sentence, and the copy stays non-judgemental — no
/// "failed", no "behind", nothing that reads as a scolding (`design.md` rule 5).
/// Before the user answers, a step is only ever *suggested*.
struct CheckInCopy {
    let unit: BodyWeightUnit
    var locale: Locale = .current

    /// - Parameters:
    ///   - currentCalories: today's target before any answer.
    ///   - accepted: `true` once the user has tapped **Use**.
    func sentence(
        for result: PaceCheckResult,
        phase: Phase,
        currentCalories: Double,
        accepted: Bool = false
    ) -> String {
        let current = calories(currentCalories)

        switch result {
        case .notEnoughData(.waiting(let daysLeft)):
            let when = daysLeft == 1 ? "tomorrow" : "in \(daysLeft) days"
            return phase.lastStepDecisionDateKey == nil
                ? "Pace needs two weeks of weigh-ins to read. The check-in reads it for the first time \(when)."
                : "A change needs two weeks to show on the scale. The check-in reads your pace again \(when)."

        case .notEnoughData(.tooFewWeighIns(let count)):
            return "Weigh in at least \(PaceCheckCalculator.minimumWeighIns) times across two weeks and the check-in can read your pace. You have \(count) so far."

        case .notEnoughData(.spanTooShort(let days)):
            return "Your weigh-ins cover \(days) \(days == 1 ? "day" : "days"). Spread them across at least \(PaceCheckCalculator.minimumSpanDays) and the check-in can read your pace."

        case .targetReached:
            return "Your trend has reached your target weight, so your calorie target stays at \(current) kcal for now."

        case .onPace(let reading):
            return "\(paceClause(reading, goal: phase.goalType)). That's the pace you picked, so your target stays at \(current) kcal."

        case .inBand(let reading):
            let offset = reading.trendKg - phase.startWeightKg
            if abs(offset) <= PaceCheckCalculator.maintainBandKg + 1e-9 {
                return "Your trend is within \(weight(PaceCheckCalculator.maintainBandKg)) of where you started, so your target stays at \(current) kcal."
            }
            return "\(bandClause(offset)) and already heading back, so your target stays at \(current) kcal."

        case .loggingGap(let reading):
            return "Food was logged on \(reading.loggedDays) of \(reading.windowDays) days. Targets move when food is logged on most days, so yours stays at \(current) kcal."

        case .atFloor:
            return "Your target is already at the lowest we set, so it stays at \(current) kcal."

        case .step(let reading, let delta, let newCalories, _):
            let lead = phase.goalType == .maintain
                ? bandClause(reading.trendKg - phase.startWeightKg)
                : paceClause(reading, goal: phase.goalType)
            let change = accepted ? "your target is now" : "we suggest"
            let direction = newCalories < currentCalories ? "down" : "up"
            // A step away from the goal means the pace was faster than chosen.
            let fasterThanChosen = (phase.goalType == .cut && delta > 0)
                || (phase.goalType == .leanBulk && delta < 0)
            let tail = fasterThanChosen ? ", to bring you back to the pace you picked" : ""
            return "\(lead), so \(change) \(calories(newCalories)) kcal, \(direction) from \(current)\(tail)."
        }
    }

    /// A signed weekly pace for a readings row — "−0.1 kg a week".
    func weeklyPace(_ kgPerWeek: Double) -> String {
        guard !roundsToZero(kgPerWeek) else { return "\(weight(0)) a week" }
        return "\(kgPerWeek < 0 ? "−" : "+")\(weight(abs(kgPerWeek))) a week"
    }

    /// "1,900", grouped for the locale.
    func calories(_ value: Double) -> String {
        Int(value.rounded()).formatted(.number.locale(locale))
    }

    /// One decimal place in the user's unit — "0.4 kg".
    func weight(_ kilograms: Double) -> String {
        let value = unit == .kilograms ? kilograms : BodyWeight.pounds(fromKilograms: kilograms)
        let formatted = value.formatted(.number.precision(.fractionLength(1)).locale(locale))
        return "\(formatted) \(unit.shortLabel)"
    }

    // MARK: - Private

    /// "You aimed to lose about 0.4 kg a week and lost about 0.1 kg a week over
    /// the last two weeks"
    private func paceClause(_ reading: PaceReading, goal: GoalType) -> String {
        let aim = goal == .leanBulk ? "gain" : "lose"
        let actual: String
        if roundsToZero(reading.paceKgPerWeek) {
            actual = "your weight held about steady"
        } else if reading.paceKgPerWeek < 0 {
            actual = "lost about \(weight(abs(reading.paceKgPerWeek))) a week"
        } else {
            actual = "gained about \(weight(abs(reading.paceKgPerWeek))) a week"
        }
        return "You aimed to \(aim) about \(weight(abs(reading.goalKgPerWeek))) a week and \(actual) over the last \(window(reading.windowDays))"
    }

    /// "Your trend is 0.8 kg above where you started"
    private func bandClause(_ offsetKg: Double) -> String {
        "Your trend is \(weight(abs(offsetKg))) \(offsetKg > 0 ? "above" : "below") where you started"
    }

    private func window(_ days: Int) -> String {
        switch days {
        case 14: return "two weeks"
        case 21: return "three weeks"
        default: return "\(days) days"
        }
    }

    /// Whether the value would display as 0.0 in the user's unit.
    private func roundsToZero(_ kilograms: Double) -> Bool {
        let value = unit == .kilograms ? kilograms : BodyWeight.pounds(fromKilograms: kilograms)
        return abs(value) < 0.05
    }
}
