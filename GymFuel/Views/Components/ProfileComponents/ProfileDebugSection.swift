//
//  ProfileDebugSection.swift
//  GymFuel
//

#if DEBUG
import SwiftUI

/// Seeds four weeks of history into the signed-in account.
///
/// The pace check in Step 4b2 and the check-in in 4b3 both need at least two
/// weeks of weigh-ins before they say anything, so without this they could only
/// be tested by waiting. There is one row per scenario, and each scenario is one
/// of the three answers the pace check can give — see
/// `DebugDataSeeder.Scenario`.
///
/// Built in the legacy Profile idiom rather than Circa, matching
/// `ProfileHealthSection`: `ProfileView` is rebuilt in one pass in Step 7a, and
/// a lone Circa card among eight material ones would read as a bug. Moot in any
/// case — `#if DEBUG` means this never ships.
struct ProfileDebugSection: View {
    let userId: String

    @State private var isWorking = false
    @State private var status: String?
    @State private var pendingScenario: DebugDataSeeder.Scenario?

    var body: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "Debug · Seed four weeks", systemImage: "hammer")

            ForEach(DebugDataSeeder.Scenario.allCases) { scenario in
                Button {
                    pendingScenario = scenario
                } label: {
                    ProfileSettingsRow(
                        title: scenario.title,
                        systemImage: "square.stack.3d.up",
                        value: isWorking ? "Working…" : Self.pace(scenario.kgPerWeek),
                        tint: .fuelOrange
                    )
                }
                .buttonStyle(.plain)
                .background(ProfileCardBackground())
                .disabled(isWorking || userId.isEmpty)
            }

            if let status {
                Text(status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 2)
            }
        }
        .padding(.horizontal)
        .alert(
            pendingScenario.map { "Seed “\($0.title)”?" } ?? "Seed?",
            isPresented: Binding(
                get: { pendingScenario != nil },
                set: { if !$0 { pendingScenario = nil } }
            ),
            presenting: pendingScenario
        ) { scenario in
            Button("Cancel", role: .cancel) {}
            Button("Seed", role: .destructive) {
                Task { await seed(scenario) }
            }
        } message: { scenario in
            Text(
                """
                Writes 28 weigh-ins at \(Self.pace(scenario.kgPerWeek)) and about 70 meals \
                to the signed-in account, overwriting any weigh-in already on those days. \
                Seeding again adds the meals again.

                Weigh-ins cannot be deleted by the app — that rule is deliberate. \
                Use a throwaway account.
                """
            )
        }
    }

    private func seed(_ scenario: DebugDataSeeder.Scenario) async {
        isWorking = true
        status = nil
        defer { isWorking = false }

        do {
            let summary = try await DebugDataSeeder().seed(scenario, userId: userId)
            status = """
            Seeded \(summary.weighInsWritten) weigh-ins at \(Self.pace(scenario.kgPerWeek)) \
            and \(summary.mealsWritten) meals across \(summary.daysLogged) logged days. \
            Assumed goal: \(Self.pace(DebugDataSeeder.Seed.assumedGoalKgPerWeek)).
            """
        } catch {
            status = "Seed failed: \(error.localizedDescription)"
        }
    }

    /// Signed, so a loss reads as a minus — the same convention as the data.
    private static func pace(_ kgPerWeek: Double) -> String {
        String(format: "%+.1f kg/wk", kgPerWeek)
    }
}
#endif
