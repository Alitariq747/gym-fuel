//
//  ProfileDebugSection.swift
//  GymFuel
//

#if DEBUG
import SwiftUI

/// Seeds four weeks of history into the signed-in account, and runs the pace
/// check against whatever the account holds.
///
/// The pace check and the weekly check-in both need at least two weeks of
/// weigh-ins before they say anything, so without this they could only be
/// tested by waiting. There is one seed row per answer the pace check can give —
/// see `DebugDataSeeder.Scenario` — plus one that starts the phase a week ago.
///
/// Built in the legacy Profile idiom rather than Circa, matching
/// `ProfileHealthSection`: `ProfileView` is rebuilt in one pass in Step 7a, and
/// a lone Circa card among eight material ones would read as a bug. Moot in any
/// case — `#if DEBUG` means this never ships.
struct ProfileDebugSection: View {
    let userId: String
    let profile: UserProfile?
    let phase: Phase?
    /// Reload profile and phase after a seed rewrites them.
    let onSeeded: () async -> Void

    @State private var isWorking = false
    @State private var status: String?
    @State private var pendingSeed: SeedChoice?

    private struct SeedChoice: Identifiable {
        let scenario: DebugDataSeeder.Scenario
        let phaseStartDaysAgo: Int

        var id: String { "\(scenario.rawValue)-\(phaseStartDaysAgo)" }

        var title: String {
            phaseStartDaysAgo == DebugDataSeeder.Seed.days - 1
                ? scenario.title
                : "\(scenario.title) · phase \(phaseStartDaysAgo) days ago"
        }
    }

    private static let choices: [SeedChoice] =
        DebugDataSeeder.Scenario.allCases.map { SeedChoice(scenario: $0, phaseStartDaysAgo: DebugDataSeeder.Seed.days - 1) }
        + [SeedChoice(scenario: .slowerThanGoal, phaseStartDaysAgo: 7)]

    var body: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "Debug · Seed four weeks", systemImage: "hammer")

            ForEach(Self.choices) { choice in
                Button {
                    pendingSeed = choice
                } label: {
                    ProfileSettingsRow(
                        title: choice.title,
                        systemImage: "square.stack.3d.up",
                        value: isWorking ? "Working…" : Self.pace(choice.scenario.kgPerWeek),
                        tint: .fuelOrange
                    )
                }
                .buttonStyle(.plain)
                .background(ProfileCardBackground())
                .disabled(isWorking || userId.isEmpty)
            }

            Button {
                Task { await runPaceCheck() }
            } label: {
                ProfileSettingsRow(
                    title: "Run pace check",
                    systemImage: "gauge.with.dots.needle.33percent",
                    value: isWorking ? "Working…" : (phase?.startDateKey ?? "No phase"),
                    tint: .fuelBlue
                )
            }
            .buttonStyle(.plain)
            .background(ProfileCardBackground())
            .disabled(isWorking || userId.isEmpty)

            if let status {
                Text(status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 2)
                    .textSelection(.enabled)
            }
        }
        .padding(.horizontal)
        .alert(
            pendingSeed.map { "Seed “\($0.title)”?" } ?? "Seed?",
            isPresented: Binding(
                get: { pendingSeed != nil },
                set: { if !$0 { pendingSeed = nil } }
            ),
            presenting: pendingSeed
        ) { choice in
            Button("Cancel", role: .cancel) {}
            Button("Seed", role: .destructive) {
                Task { await seed(choice) }
            }
        } message: { choice in
            Text(
                """
                Writes 28 weigh-ins at \(Self.pace(choice.scenario.kgPerWeek)) and about 70 meals \
                to the signed-in account, sets the goal to Lose fat · Gentle, and starts a phase \
                \(choice.phaseStartDaysAgo) days ago. Seeding again adds the meals again.

                Weigh-ins and phases cannot be deleted by the app — that rule is deliberate. \
                Use a throwaway account.
                """
            )
        }
    }

    private func seed(_ choice: SeedChoice) async {
        isWorking = true
        status = nil
        defer { isWorking = false }

        do {
            let summary = try await DebugDataSeeder().seed(
                choice.scenario,
                phaseStartDaysAgo: choice.phaseStartDaysAgo,
                userId: userId
            )
            await onSeeded()
            status = """
            Seeded \(summary.weighInsWritten) weigh-ins at \(Self.pace(choice.scenario.kgPerWeek)) \
            and \(summary.mealsWritten) meals across \(summary.daysLogged) logged days. \
            Phase from \(summary.phaseStartDateKey), goal \(Self.pace(DebugDataSeeder.Seed.assumedGoalKgPerWeek)).
            """
        } catch {
            status = "Seed failed: \(error.localizedDescription)"
        }
    }

    /// Fetches what the check-in will fetch and prints the rule's answer.
    private func runPaceCheck() async {
        guard let profile, let phase else {
            status = "No phase loaded yet. Seed first, or close and reopen Settings."
            return
        }
        let calculator = MacroTargetCalculator()
        guard let bounds = calculator.calorieBounds(for: profile) else {
            status = "The profile is missing age, height or weight."
            return
        }

        isWorking = true
        status = nil
        defer { isWorking = false }

        let now = Date.now
        let calendar = DateKey.calendar()
        let todayKey = DateKey.key(for: now)
        let startOfToday = calendar.startOfDay(for: now)

        guard let oldest = calendar.date(byAdding: .day, value: -(DebugDataSeeder.Seed.days - 1), to: now),
              let windowStart = calendar.date(byAdding: .day, value: -(PaceCheckCalculator.maximumWindowDays - 1), to: startOfToday),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)
        else { return }

        do {
            let weighIns = try await FirebaseWeighInService().fetchWeighIns(
                for: userId,
                fromKey: DateKey.key(for: oldest),
                throughKey: todayKey
            )
            let entries = try await FirebaseLogEntryService().fetchEntries(
                for: userId,
                from: windowStart,
                to: tomorrow
            )
            let loggedDayKeys = Set(
                entries.filter { $0.status == .succeeded }.map { DateKey.key(for: $0.loggedAt) }
            )

            let result = PaceCheckCalculator().evaluate(
                PaceCheckCalculator.Input(
                    weighIns: weighIns,
                    phase: phase,
                    loggedDayKeys: loggedDayKeys,
                    todayKey: todayKey,
                    baseCalories: bounds.base,
                    floorCalories: bounds.floor
                )
            )
            status = Self.describe(result)
        } catch {
            status = "Pace check failed: \(error.localizedDescription)"
        }
    }

    private static func describe(_ result: PaceCheckResult) -> String {
        let headline: String
        switch result {
        case .notEnoughData(.waiting(let daysLeft)):
            return "Not enough data yet — \(daysLeft) more days before a check."
        case .notEnoughData(.tooFewWeighIns(let count)):
            return "Not enough data yet — \(count) weigh-ins in the window, needs \(PaceCheckCalculator.minimumWeighIns)."
        case .notEnoughData(.spanTooShort(let days)):
            return "Not enough data yet — weigh-ins span \(days) days, needs \(PaceCheckCalculator.minimumSpanDays)."
        case .targetReached:
            headline = "Target weight reached — would offer Maintain."
        case .onPace:
            headline = "No change — on pace."
        case .inBand:
            headline = "No change — inside the maintain band."
        case .loggingGap(let reading):
            headline = "No change — food logged on \(reading.loggedDays) of \(reading.windowDays) days."
        case .atFloor:
            headline = "No change — already at the calorie floor."
        case .step(_, let delta, let newCalories, let newAdjustment):
            headline = String(
                format: "Step %+.0f kcal → %.0f kcal (adjustment %+.0f).",
                delta, newCalories, newAdjustment
            )
        }

        guard let reading = result.reading else { return headline }
        return headline + String(
            format: " Pace %+.2f vs goal %+.2f kg/wk · trend %.1f kg · %d weigh-ins · %d/%d days logged.",
            reading.paceKgPerWeek,
            reading.goalKgPerWeek,
            reading.trendKg,
            reading.weighInCount,
            reading.loggedDays,
            reading.windowDays
        )
    }

    /// Signed, so a loss reads as a minus — the same convention as the data.
    private static func pace(_ kgPerWeek: Double) -> String {
        String(format: "%+.1f kg/wk", kgPerWeek)
    }
}
#endif
