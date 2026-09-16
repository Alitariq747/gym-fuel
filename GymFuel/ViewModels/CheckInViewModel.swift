//
//  CheckInViewModel.swift
//  GymFuel
//

import Foundation

/// Owns the weekly check-in: whether one is open, what the pace check says, and
/// the one write that can move a target.
///
/// Owned by `StatsView`, which shows the card, and passed to `CheckInView`, which
/// answers it — so an answer hides the card without a refetch.
///
/// **Never touches `UserProfileViewModel.errorMessage`.** Errors stay on the
/// sheet; the caller applies a saved answer to the phase in memory.
@MainActor
final class CheckInViewModel: ObservableObject {
    struct Evaluation: Equatable {
        let dueDateKey: String
        /// The phase the rule ran against. An answer is only written while the
        /// phase in memory still equals it.
        let phase: Phase
        let result: PaceCheckResult
        let context: CheckInContext
        /// The days `context` covers: the pace check's window, or the last 7.
        let contextWindowDays: Int
        let targetsBefore: Macros
        /// Only for a `.step`.
        let targetsAfter: Macros?
    }

    struct Answer {
        let checkIn: CheckIn
        let phaseUpdate: PhaseDecisionUpdate?
    }

    /// The context window when the pace check had no window of its own.
    static let contextFallbackDays = 7

    @Published private(set) var latest: CheckIn?
    /// `false` until the newest check-in has been read, so the card never shows
    /// for a check-in that was already answered.
    @Published private(set) var hasLoadedLatest = false
    @Published private(set) var evaluation: Evaluation?
    @Published private(set) var isEvaluating = false
    @Published private(set) var isSaving = false
    /// The answer saved on the open sheet.
    @Published private(set) var saved: CheckIn?
    @Published private(set) var errorMessage: String?

    private let checkInService: CheckInService
    private let weighInService: WeighInService
    private let logEntryService: LogEntryService
    private let macroTargetCalculator: MacroTargetCalculator
    private let paceCheckCalculator: PaceCheckCalculator
    private let networkMonitor: NetworkMonitoring

    init(
        checkInService: CheckInService = FirebaseCheckInService(),
        weighInService: WeighInService = FirebaseWeighInService(),
        logEntryService: LogEntryService = FirebaseLogEntryService(),
        macroTargetCalculator: MacroTargetCalculator = MacroTargetCalculator(),
        paceCheckCalculator: PaceCheckCalculator = PaceCheckCalculator(),
        networkMonitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.checkInService = checkInService
        self.weighInService = weighInService
        self.logEntryService = logEntryService
        self.macroTargetCalculator = macroTargetCalculator
        self.paceCheckCalculator = paceCheckCalculator
        self.networkMonitor = networkMonitor
    }

    // MARK: - Is one open?

    func openDueDateKey(for phase: Phase?, now: Date = .now) -> String? {
        guard hasLoadedLatest, let phase else { return nil }
        return CheckInSchedule(phase: phase, latest: latest, todayKey: DateKey.key(for: now)).openDueDateKey
    }

    func loadLatest(userId: String) async {
        guard !userId.isEmpty else { return }
        do {
            latest = try await checkInService.fetchLatestCheckIn(for: userId)
            hasLoadedLatest = true
        } catch {
            FirebaseTelemetryService.recordNonFatal(error, reason: "check_in_fetch_failed", metadata: [:])
        }
    }

    // MARK: - The sheet

    /// Clears what the previous sheet showed.
    func reset() {
        evaluation = nil
        saved = nil
        errorMessage = nil
    }

    /// Fetches what the pace check reads and runs it — the same inputs
    /// `ProfileDebugSection`'s "Run pace check" assembles.
    func evaluate(
        userId: String,
        profile: UserProfile,
        phase: Phase,
        dueDateKey: String,
        now: Date = .now
    ) async {
        // Once answered, the sheet keeps showing the answer even though the
        // phase it changed has moved on.
        guard saved == nil else { return }

        guard let bounds = macroTargetCalculator.calorieBounds(for: profile),
              let targetsBefore = macroTargetCalculator.targetMacros(
                for: profile,
                calorieAdjustment: phase.calorieAdjustment
              )
        else {
            errorMessage = "Your profile is missing age, height or weight."
            return
        }

        let calendar = DateKey.calendar()
        let todayKey = DateKey.key(for: now)
        let startOfToday = calendar.startOfDay(for: now)

        guard let trendStart = calendar.date(byAdding: .day, value: -StatsViewModel.trendWindowDays, to: startOfToday),
              let entriesStart = calendar.date(byAdding: .day, value: -(PaceCheckCalculator.maximumWindowDays - 1), to: startOfToday),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)
        else { return }

        isEvaluating = true
        errorMessage = nil
        defer { isEvaluating = false }

        do {
            let weighIns = try await weighInService.fetchWeighIns(
                for: userId,
                fromKey: DateKey.key(for: trendStart),
                throughKey: todayKey
            )
            let entries = try await logEntryService.fetchEntries(for: userId, from: entriesStart, to: tomorrow)
                .filter { $0.status == .succeeded }

            let result = paceCheckCalculator.evaluate(
                PaceCheckCalculator.Input(
                    weighIns: weighIns,
                    phase: phase,
                    loggedDayKeys: Set(entries.map { DateKey.key(for: $0.loggedAt) }),
                    todayKey: todayKey,
                    baseCalories: bounds.base,
                    floorCalories: bounds.floor
                )
            )

            let windowDays = result.reading?.windowDays ?? Self.contextFallbackDays
            evaluation = Evaluation(
                dueDateKey: dueDateKey,
                phase: phase,
                result: result,
                context: Self.context(entries: entries, windowDays: windowDays, startOfToday: startOfToday, calendar: calendar),
                contextWindowDays: windowDays,
                targetsBefore: targetsBefore,
                targetsAfter: CheckIn.suggestedTargets(for: result, profile: profile, calculator: macroTargetCalculator)
            )
            FirebaseTelemetryService.logCheckInEvent("opened", decision: CheckIn.Decision(result).rawValue)
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't load your check-in. Please try again."
            )
            FirebaseTelemetryService.recordNonFatal(error, reason: "check_in_evaluate_failed", metadata: ["dueDateKey": dueDateKey])
        }
    }

    /// Saves **Use**, **Keep my target** or **Done**.
    ///
    /// - Returns: the saved answer, for the caller to apply to the phase in
    ///   memory; `nil` if nothing was written.
    func answer(
        _ response: CheckIn.Response,
        userId: String,
        currentPhase: Phase?,
        now: Date = .now
    ) async -> Answer? {
        guard let evaluation, saved == nil, !isSaving else { return nil }
        guard !userId.isEmpty else {
            errorMessage = "We couldn't tell which account to save this to. Please try again."
            return nil
        }

        // A suggestion worked out against a phase that has since changed must
        // not overwrite that change. The sheet re-reads when the phase moves.
        guard currentPhase == evaluation.phase else {
            errorMessage = "Your goal or pace changed while this was open. Take another look before you choose."
            return nil
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let checkIn = CheckIn.make(
            result: evaluation.result,
            phaseStartDateKey: evaluation.phase.startDateKey,
            dueDateKey: evaluation.dueDateKey,
            response: response,
            context: evaluation.context,
            targetsBefore: evaluation.targetsBefore,
            targetsAfter: evaluation.targetsAfter,
            now: now
        )
        let phaseUpdate = checkIn.phaseUpdate(from: evaluation.result)

        do {
            // Firestore's completion fires only on server acknowledgement, so
            // awaiting offline never resumes. Commit into the cache instead, as
            // weigh-ins do.
            if networkMonitor.isConnected {
                try await checkInService.saveCheckIn(checkIn, phaseUpdate: phaseUpdate, for: userId)
            } else {
                try checkInService.saveCheckInLocally(checkIn, phaseUpdate: phaseUpdate, for: userId)
            }
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't save your check-in. Please try again."
            )
            FirebaseTelemetryService.recordNonFatal(error, reason: "check_in_save_failed", metadata: ["dueDateKey": checkIn.dueDateKey])
            return nil
        }

        latest = checkIn
        saved = checkIn
        FirebaseTelemetryService.logCheckInEvent(checkIn.response.rawValue, decision: checkIn.decision.rawValue)
        return Answer(checkIn: checkIn, phaseUpdate: phaseUpdate)
    }

    // MARK: - Context

    /// Days logged and the mean over **logged days only** (decision 4).
    static func context(
        entries: [LogEntry],
        windowDays: Int,
        startOfToday: Date,
        calendar: Calendar
    ) -> CheckInContext {
        guard let windowStart = calendar.date(byAdding: .day, value: -(windowDays - 1), to: startOfToday) else {
            return CheckInContext(loggedDays: 0, averageLoggedCalories: 0)
        }
        let inWindow = entries.filter { $0.loggedAt >= windowStart }
        let loggedDays = Set(inWindow.map { DateKey.key(for: $0.loggedAt, timeZone: calendar.timeZone) }).count
        let total = inWindow.compactMap { $0.feedback?.macros }.reduce(0) { $0 + $1.calories }
        return CheckInContext(
            loggedDays: loggedDays,
            averageLoggedCalories: loggedDays > 0 ? total / Double(loggedDays) : 0
        )
    }
}
