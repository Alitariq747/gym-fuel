//
//  DebugDataSeeder.swift
//  GymFuel
//

#if DEBUG
import Foundation

/// Writes four weeks of synthetic weigh-ins and meals, sets the goal they are
/// measured against, and starts a phase — so the pace check can be looked at
/// instead of waited for.
///
/// The pace check in `build-order.md` Step 4 needs two weeks of weigh-ins before
/// it says anything, and the check-in needs more. Tapping a month in by hand is
/// not a plan; this is.
///
/// **Three scenarios, one per answer the pace check can give.** Each writes a
/// weight trajectory at a fixed weekly pace, measured against Lose fat · Gentle
/// (0.5 % a week — about 0.4 kg at the starting weight below). Gentle, not
/// Steady: at Steady the "faster" scenario would read as on pace.
/// `PaceCheckCalculator` answers *step the target down*, *no change* and *step it
/// up*, in that order. Starting the phase 7 days ago instead answers *not enough
/// data yet*.
///
/// `#if DEBUG` wraps the whole file, so none of this exists in a release build.
///
/// - Warning: **Seed only on a throwaway account.** `firestore.rules` sets
///   `allow delete: if false` on `weighIns` and `phases` — deliberately — so the
///   client cannot remove them afterwards. Log entries can be deleted; weigh-ins
///   and phases are permanent for that account.
struct DebugDataSeeder {
    enum Scenario: String, CaseIterable, Identifiable {
        case slowerThanGoal
        case onGoal
        case fasterThanGoal

        var id: String { rawValue }

        /// **Signed: negative means losing.**
        var kgPerWeek: Double {
            switch self {
            case .slowerThanGoal: return -0.1
            case .onGoal: return -0.4
            case .fasterThanGoal: return -0.8
            }
        }

        var title: String {
            switch self {
            case .slowerThanGoal: return "Slower than goal"
            case .onGoal: return "On goal"
            case .fasterThanGoal: return "Faster than goal"
            }
        }
    }

    enum Seed {
        static let goal: GoalType = .cut
        static let pace: GoalPace = .gentle
        static let startWeightKg: Double = 83.0
        /// The goal every scenario is measured against. **Signed: negative means
        /// losing.**
        static var assumedGoalKgPerWeek: Double {
            pace.kgPerWeek(for: goal, weightKg: startWeightKg)
        }
        static let days: Int = 28
        /// An ordinary day of eating. Nothing reads these calories back: the pace
        /// check only asks *whether* a day was logged.
        static let dailyCalories: Double = 2000
    }

    struct Summary {
        let scenario: Scenario
        let weighInsWritten: Int
        let mealsWritten: Int
        let daysLogged: Int
        let phaseStartDateKey: String
    }

    private let weighInService: WeighInService
    private let logEntryService: LogEntryService
    private let profileService: FirebaseUserProfileService
    private let phaseService: PhaseService
    private let calculator: MacroTargetCalculator

    init(
        weighInService: WeighInService = FirebaseWeighInService(),
        logEntryService: LogEntryService = FirebaseLogEntryService(),
        profileService: FirebaseUserProfileService = .shared,
        phaseService: PhaseService = FirebasePhaseService(),
        calculator: MacroTargetCalculator = MacroTargetCalculator()
    ) {
        self.weighInService = weighInService
        self.logEntryService = logEntryService
        self.profileService = profileService
        self.phaseService = phaseService
        self.calculator = calculator
    }

    /// The weigh-ins `seed` writes, oldest first, without writing them. Tests
    /// run the pace check against exactly this data.
    static func weighIns(for scenario: Scenario, now: Date = .now, timeZone: TimeZone = .current) -> [WeighIn] {
        let calendar = DateKey.calendar(timeZone: timeZone)
        return weighIns(from: dayPlans(for: scenario, now: now, calendar: calendar), timeZone: timeZone)
    }

    /// Writes `Seed.days` of weigh-ins ending today, meals on most of them, the
    /// Lose fat · Gentle goal, and a phase starting `phaseStartDaysAgo` days ago.
    ///
    /// Writes go through the same awaited service calls the app uses, not the
    /// local-cache variants, so a rules rejection surfaces as an error here
    /// rather than as data that silently never arrives.
    ///
    /// Seeding again overwrites the same 28 weigh-in days and the phase — each
    /// is keyed by day — but adds a second copy of every meal, since each entry
    /// gets a new ID.
    @discardableResult
    func seed(
        _ scenario: Scenario,
        phaseStartDaysAgo: Int = Seed.days - 1,
        userId: String,
        now: Date = .now,
        timeZone: TimeZone = .current
    ) async throws -> Summary {
        guard !userId.isEmpty else { throw DebugSeedError.noSignedInUser }

        let calendar = DateKey.calendar(timeZone: timeZone)
        let plan = Self.dayPlans(for: scenario, now: now, calendar: calendar)

        // Everything is turned into finished `WeighIn` and `LogEntry` values
        // before any task starts, so the group below captures only Sendable
        // models and the two services — never the plan's private value types.
        let weighIns = Self.weighIns(from: plan, timeZone: timeZone)
        let entries = plan.flatMap { day in day.meals.map { $0.entry(userId: userId) } }

        let weighInService = self.weighInService
        let logEntryService = self.logEntryService

        try await withThrowingTaskGroup(of: Void.self) { group in
            for weighIn in weighIns {
                group.addTask {
                    try await weighInService.saveWeighIn(weighIn, for: userId)
                }
            }
            for entry in entries {
                group.addTask {
                    try await logEntryService.saveEntry(entry)
                }
            }
            try await group.waitForAll()
        }

        // The goal the scenarios are measured against, and the weight a real
        // weigh-in would have left on the profile.
        var profile = try await profileService.fetchProfile(for: userId)
        profile.goalType = Seed.goal
        profile.goalPace = Seed.pace
        profile.targetWeightKg = nil
        if let latest = weighIns.last {
            profile.weightKg = latest.weightKg
        }
        let savedProfile = try await profileService.updateProfile(profile)

        let startIndex = min(max(weighIns.count - 1 - phaseStartDaysAgo, 0), weighIns.count - 1)
        guard weighIns.indices.contains(startIndex) else { throw DebugSeedError.incompleteProfile }
        let start = weighIns[startIndex]

        // The targets as they were on the phase's first day, at that day's weight.
        var profileAtStart = savedProfile
        profileAtStart.weightKg = start.weightKg
        guard let startTargets = calculator.targetMacros(for: profileAtStart) else {
            throw DebugSeedError.incompleteProfile
        }

        let phase = Phase(
            startDateKey: start.dateKey,
            goalType: Seed.goal,
            goalPace: Seed.pace,
            pacePercentPerWeek: Seed.pace.percentPerWeek(for: Seed.goal),
            startWeightKg: start.weightKg,
            targetWeightKg: nil,
            startTargets: startTargets,
            calorieAdjustment: 0,
            lastStepDecisionDateKey: nil,
            // Now, not the start day: the current phase is the newest by
            // `startedAt`, and the account already has `phases/{today}` from
            // onboarding.
            startedAt: now
        )
        try await phaseService.startPhase(phase, for: userId)

        return Summary(
            scenario: scenario,
            weighInsWritten: weighIns.count,
            mealsWritten: entries.count,
            daysLogged: plan.filter { !$0.meals.isEmpty }.count,
            phaseStartDateKey: start.dateKey
        )
    }

    // MARK: - The synthetic month

    private struct MealPlan {
        let loggedAt: Date
        let title: String
        let rawInput: String
        let macros: Macros

        func entry(userId: String) -> LogEntry {
            LogEntry(
                userId: userId,
                source: .text,
                status: .succeeded,
                loggedAt: loggedAt,
                title: title,
                rawInput: rawInput,
                feedback: LogEntryFeedback(
                    explanation: "Seeded by the debug tools.",
                    assumptions: [],
                    confidence: 0.8,
                    macros: macros,
                    goalFitScore: nil,
                    estimatedItems: nil
                )
            )
        }
    }

    private struct DayPlan {
        let date: Date
        let weightKg: Double
        let meals: [MealPlan]
    }

    /// Day-to-day variation around `Seed.dailyCalories`, cycled across logged
    /// days, so the timeline does not look stamped out.
    private static let intakeOffsets: [Double] = [-300, 250, -150, 200, -100, 100]

    /// Day-to-day scale noise, in kg. Fixed rather than random so seeding the
    /// same scenario twice draws the same chart — a seeder you cannot reproduce is
    /// a poor witness. Zero-mean, and the first day sits exactly on the line.
    private static let weightNoiseKg: [Double] = [0, 0.25, -0.2, 0.15, -0.3, 0.1, 0.2, -0.15]

    private static func weighIns(from plan: [DayPlan], timeZone: TimeZone) -> [WeighIn] {
        plan.map { day in
            WeighIn(
                dateKey: DateKey.key(for: day.date, timeZone: timeZone),
                weightKg: BodyWeight.roundedForStorage(day.weightKg),
                loggedAt: day.date,
                source: .manual
            )
        }
    }

    private static func dayPlans(for scenario: Scenario, now: Date, calendar: Calendar) -> [DayPlan] {
        let perDayChange = scenario.kgPerWeek / 7
        var loggedDayIndex = 0

        return (0..<Seed.days).compactMap { offset -> DayPlan? in
            // offset 0 is the oldest day; the last one is today.
            let daysAgo = Seed.days - 1 - offset
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else {
                return nil
            }

            let noise = weightNoiseKg[offset % weightNoiseKg.count]
            let weightKg = Seed.startWeightKg + (perDayChange * Double(offset)) + noise

            // One unlogged day a week — 24 logged days of 28, comfortably inside
            // the pace check's "food logged on most days" rule.
            let skipsLogging = offset % 7 == 5
            guard !skipsLogging else {
                return DayPlan(date: date, weightKg: weightKg, meals: [])
            }

            let offsetForDay = intakeOffsets[loggedDayIndex % intakeOffsets.count]
            loggedDayIndex += 1

            return DayPlan(
                date: date,
                weightKg: weightKg,
                meals: meals(on: date, totalCalories: Seed.dailyCalories + offsetForDay, calendar: calendar)
            )
        }
    }

    private static let mealTemplates: [(hour: Int, title: String, rawInput: String, share: Double)] = [
        (8, "Breakfast", "two eggs, toast and a flat white", 0.25),
        (13, "Lunch", "chicken and rice bowl with salad", 0.35),
        (19, "Dinner", "salmon, potatoes and greens", 0.30),
        (21, "Snack", "yoghurt and a handful of almonds", 0.10),
    ]

    private static func meals(on date: Date, totalCalories: Double, calendar: Calendar) -> [MealPlan] {
        // Two to four meals, cycling by day so the timeline does not look
        // stamped out.
        let count = 2 + (calendar.component(.day, from: date) % 3)
        let templates = Array(mealTemplates.prefix(count))
        let shareTotal = templates.reduce(0) { $0 + $1.share }

        return templates.map { template in
            let calories = totalCalories * (template.share / shareTotal)
            return MealPlan(
                loggedAt: calendar.date(bySettingHour: template.hour, minute: 30, second: 0, of: date) ?? date,
                title: template.title,
                rawInput: template.rawInput,
                macros: macros(forCalories: calories)
            )
        }
    }

    /// A plausible split — 30% protein, 40% carbohydrate, 30% fat by calories —
    /// using the Atwater factors the Sources screen already cites.
    private static func macros(forCalories calories: Double) -> Macros {
        Macros(
            calories: calories.rounded(),
            protein: (calories * 0.30 / 4).rounded(),
            carbs: (calories * 0.40 / 4).rounded(),
            fat: (calories * 0.30 / 9).rounded()
        )
    }
}

enum DebugSeedError: LocalizedError {
    case noSignedInUser
    case incompleteProfile

    var errorDescription: String? {
        switch self {
        case .noSignedInUser: return "No signed-in account to seed."
        case .incompleteProfile: return "The signed-in profile is missing age, height or weight."
        }
    }
}
#endif
