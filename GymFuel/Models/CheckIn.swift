//
//  CheckIn.swift
//  GymFuel
//

import Foundation

/// The food log over a check-in's window, shown as context only — never an
/// input to the pace rule, never coloured (decision 4).
struct CheckInContext: Equatable, Sendable {
    let loggedDays: Int
    /// Mean calories across **logged days only**, so a missed day does not read
    /// as undereating. 0 when nothing was logged.
    let averageLoggedCalories: Double
}

/// One weekly check-in, as answered.
///
/// `dueDateKey` **is** the Firestore document ID (`"yyyy-MM-dd"`), like
/// `Phase.startDateKey`. The sentence the user read is not stored — it is
/// rebuilt from these fields by `CheckInCopy`.
struct CheckIn: Identifiable, Equatable, Sendable {
    /// Which answer the pace rule gave. Mirrors `PaceCheckResult`.
    enum Decision: String, Codable, Sendable {
        case notEnoughData
        case targetReached
        case onPace
        case inBand
        case loggingGap
        case atFloor
        case step
    }

    enum Response: String, Codable, Sendable {
        /// **Use** — the suggested step was applied.
        case accepted
        /// **Keep my target** — a step was suggested and declined.
        case rejected
        /// **Done** — there was nothing to decide.
        case acknowledged
    }

    let dueDateKey: String
    let phaseStartDateKey: String
    let decision: Decision
    let response: Response
    /// **Signed: negative means losing.** `nil` when there was no reading.
    let paceKgPerWeek: Double?
    /// **Signed.** `nil` when there was no reading.
    let goalKgPerWeek: Double?
    let weighInCount: Int?
    let windowDays: Int?
    let loggedDays: Int
    let averageLoggedCalories: Double
    /// The change the rule suggested, kept even when it was declined.
    let suggestedDelta: Double?
    let targetsBefore: Macros
    /// Equal to `targetsBefore` unless the step was accepted.
    let targetsAfter: Macros
    /// The day the user answered. 4b4c places a target change on this day.
    let completedDateKey: String
    let completedAt: Date

    var id: String { dueDateKey }
}

extension CheckIn.Decision {
    init(_ result: PaceCheckResult) {
        switch result {
        case .notEnoughData: self = .notEnoughData
        case .targetReached: self = .targetReached
        case .onPace: self = .onPace
        case .inBand: self = .inBand
        case .loggingGap: self = .loggingGap
        case .atFloor: self = .atFloor
        case .step: self = .step
        }
    }
}

extension CheckIn {
    /// Builds the record for an answer. Pure, so the rules below are tested
    /// without Firestore:
    ///
    /// - only a `.step` can be accepted or rejected; anything else is
    ///   acknowledged whatever the caller passed
    /// - `targetsAfter` equals `targetsBefore` unless the step was accepted
    static func make(
        result: PaceCheckResult,
        phaseStartDateKey: String,
        dueDateKey: String,
        response: Response,
        context: CheckInContext,
        targetsBefore: Macros,
        targetsAfter: Macros?,
        now: Date,
        timeZone: TimeZone = .current
    ) -> CheckIn {
        let reading = result.reading
        let suggestedDelta: Double?
        let resolvedResponse: Response

        if case .step(_, let delta, _, _) = result {
            suggestedDelta = delta
            resolvedResponse = response
        } else {
            suggestedDelta = nil
            resolvedResponse = .acknowledged
        }

        return CheckIn(
            dueDateKey: dueDateKey,
            phaseStartDateKey: phaseStartDateKey,
            decision: Decision(result),
            response: resolvedResponse,
            paceKgPerWeek: reading?.paceKgPerWeek,
            goalKgPerWeek: reading?.goalKgPerWeek,
            weighInCount: reading?.weighInCount,
            windowDays: reading?.windowDays,
            loggedDays: context.loggedDays,
            averageLoggedCalories: context.averageLoggedCalories,
            suggestedDelta: suggestedDelta,
            targetsBefore: targetsBefore,
            targetsAfter: resolvedResponse == .accepted ? (targetsAfter ?? targetsBefore) : targetsBefore,
            completedDateKey: DateKey.key(for: now, timeZone: timeZone),
            completedAt: now
        )
    }

    /// The full targets if a suggested step is used — the formula with the
    /// step's new adjustment. `nil` for anything but a `.step`.
    static func suggestedTargets(
        for result: PaceCheckResult,
        profile: UserProfile,
        calculator: MacroTargetCalculator = MacroTargetCalculator()
    ) -> Macros? {
        guard case .step(_, _, _, let newAdjustment) = result else { return nil }
        return calculator.targetMacros(for: profile, calorieAdjustment: newAdjustment)
    }

    /// What the answer changes on the phase. **Use** sets the new adjustment
    /// and the decision date; **Keep my target** sets the decision date only,
    /// which starts the same 14-day wait (decision 2); **Done** changes nothing.
    func phaseUpdate(from result: PaceCheckResult) -> PhaseDecisionUpdate? {
        switch (response, result) {
        case (.accepted, .step(_, _, _, let newAdjustment)):
            return PhaseDecisionUpdate(
                phaseKey: phaseStartDateKey,
                calorieAdjustment: newAdjustment,
                decisionDateKey: completedDateKey
            )
        case (.rejected, .step):
            return PhaseDecisionUpdate(
                phaseKey: phaseStartDateKey,
                calorieAdjustment: nil,
                decisionDateKey: completedDateKey
            )
        default:
            return nil
        }
    }
}
