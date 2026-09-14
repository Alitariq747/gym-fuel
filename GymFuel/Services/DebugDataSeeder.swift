//
//  DebugDataSeeder.swift
//  GymFuel
//

#if DEBUG
import Foundation

/// Writes four weeks of synthetic weigh-ins and meals so the pace check can be
/// looked at instead of waited for.
///
/// The pace check in `build-order.md` Step 4 needs two weeks of weigh-ins before
/// it says anything, and the check-in needs more. Tapping a month in by hand is
/// not a plan; this is.
///
/// **Three scenarios, one per answer the pace check can give.** Each writes a
/// weight trajectory at a fixed weekly pace, measured against a "Lose fat" goal of
/// about 0.4 kg a week — slower than that, on it, and faster. Step 4b2's pace
/// check should answer *step the target down*, *no change* and *step it up*, in
/// that order. The goal itself is not written anywhere: `phases` does not exist
/// until 4b2, so each scenario states the goal it assumes rather than setting it.
///
/// `#if DEBUG` wraps the whole file, so none of this exists in a release build.
///
/// - Warning: **Seed only on a throwaway account.** `firestore.rules` sets
///   `allow delete: if false` on `weighIns` — deliberately, from 4a — so the
///   client cannot remove a seeded weigh-in afterwards. Log entries can be
///   deleted; weigh-ins are permanent for that account.
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
        /// The goal every scenario is measured against — "Lose fat" at roughly
        /// 0.5% a week for the starting weight below. **Signed: negative means
        /// losing.**
        static let assumedGoalKgPerWeek: Double = -0.4
        static let startWeightKg: Double = 83.0
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
    }

    private let weighInService: WeighInService
    private let logEntryService: LogEntryService

    init(
        weighInService: WeighInService = FirebaseWeighInService(),
        logEntryService: LogEntryService = FirebaseLogEntryService()
    ) {
        self.weighInService = weighInService
        self.logEntryService = logEntryService
    }

    /// Writes `Seed.days` of weigh-ins ending today, plus meals on most of them.
    ///
    /// Writes go through the same awaited service calls the app uses, not the
    /// local-cache variants, so a rules rejection surfaces as an error here
    /// rather than as data that silently never arrives.
    ///
    /// Seeding again overwrites the same 28 weigh-in days — a day is a document
    /// ID — but adds a second copy of every meal, since each entry gets a new ID.
    @discardableResult
    func seed(
        _ scenario: Scenario,
        userId: String,
        now: Date = .now,
        timeZone: TimeZone = .current
    ) async throws -> Summary {
        guard !userId.isEmpty else { throw DebugSeedError.noSignedInUser }

        let calendar = DateKey.calendar(timeZone: timeZone)
        let plan = dayPlans(for: scenario, now: now, calendar: calendar)

        // Everything is turned into finished `WeighIn` and `LogEntry` values
        // before any task starts, so the group below captures only Sendable
        // models and the two services — never the plan's private value types.
        let weighIns = plan.map { day in
            WeighIn(
                dateKey: DateKey.key(for: day.date, timeZone: timeZone),
                weightKg: BodyWeight.roundedForStorage(day.weightKg),
                loggedAt: day.date,
                source: .manual
            )
        }
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

        return Summary(
            scenario: scenario,
            weighInsWritten: weighIns.count,
            mealsWritten: entries.count,
            daysLogged: plan.filter { !$0.meals.isEmpty }.count
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

    private func dayPlans(for scenario: Scenario, now: Date, calendar: Calendar) -> [DayPlan] {
        let perDayChange = scenario.kgPerWeek / 7
        var loggedDayIndex = 0

        return (0..<Seed.days).compactMap { offset -> DayPlan? in
            // offset 0 is the oldest day; the last one is today.
            let daysAgo = Seed.days - 1 - offset
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else {
                return nil
            }

            let noise = Self.weightNoiseKg[offset % Self.weightNoiseKg.count]
            let weightKg = Seed.startWeightKg + (perDayChange * Double(offset)) + noise

            // One unlogged day a week — 24 logged days of 28, comfortably inside
            // the pace check's "food logged on most days" rule.
            let skipsLogging = offset % 7 == 5
            guard !skipsLogging else {
                return DayPlan(date: date, weightKg: weightKg, meals: [])
            }

            let offsetForDay = Self.intakeOffsets[loggedDayIndex % Self.intakeOffsets.count]
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

    private func meals(on date: Date, totalCalories: Double, calendar: Calendar) -> [MealPlan] {
        // Two to four meals, cycling by day so the timeline does not look
        // stamped out.
        let count = 2 + (calendar.component(.day, from: date) % 3)
        let templates = Array(Self.mealTemplates.prefix(count))
        let shareTotal = templates.reduce(0) { $0 + $1.share }

        return templates.map { template in
            let calories = totalCalories * (template.share / shareTotal)
            return MealPlan(
                loggedAt: calendar.date(bySettingHour: template.hour, minute: 30, second: 0, of: date) ?? date,
                title: template.title,
                rawInput: template.rawInput,
                macros: Self.macros(forCalories: calories)
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

    var errorDescription: String? {
        switch self {
        case .noSignedInUser: return "No signed-in account to seed."
        }
    }
}
#endif
