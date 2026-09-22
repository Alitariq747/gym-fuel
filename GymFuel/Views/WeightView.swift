//
//  WeightView.swift
//  GymFuel
//

import SwiftUI

/// The user's weigh-ins against their plan. Opens from the Week card until 7
/// puts it in the menu.
///
/// **Nothing here judges.** No red, no "behind", no advice: the chart shows where
/// the weigh-ins are and where the plan heads, and the user reads the distance.
struct WeightView: View {
    @EnvironmentObject private var profileVm: UserProfileViewModel
    @EnvironmentObject private var healthWeightSync: HealthWeightSyncService
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(BodyWeightUnit.preferenceKey) private var unitRawValue = BodyWeightUnit.kilograms.rawValue
    @StateObject private var viewModel = WeightViewModel()
    @State private var isTargetsPresented = false
    @State private var isConfirmingMaintain = false
    @State private var weighInToDelete: WeighIn?

    private var unit: BodyWeightUnit {
        BodyWeightUnit(rawValue: unitRawValue) ?? .kilograms
    }

    /// Read from the live profile, so a goal changed on the targets screen redraws
    /// the line the moment it saves.
    private var plan: WeightPlan? {
        profileVm.profile.flatMap { WeightPlan(profile: $0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                if let goalKg = reachedGoalKg {
                    goalNote(goalKg)
                }

                CircaCard {
                    WeightChart(series: viewModel.series, unit: unit, domain: viewModel.chartDomain(), plan: plan)
                }

                Button("Adjust targets") { isTargetsPresented = true }
                    .buttonStyle(.circa(.secondary))

                if let message = viewModel.errorMessage ?? profileVm.errorMessage {
                    Text(message)
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaDanger)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let weighIns = viewModel.weighIns {
                    weighInList(weighIns)
                }
            }
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.vertical, 18)
        }
        .circaPaper()
        .navigationBarTitleDisplayMode(.inline)
        .task(id: profileVm.profile?.id) {
            await viewModel.load(userId: profileVm.profile?.id ?? "")
        }
        // A new presentation, so it is handed the appearance this screen already has.
        .sheet(isPresented: $isTargetsPresented) {
            TargetsView()
                .preferredColorScheme(colorScheme)
        }
        .confirmationDialog(
            "Delete this weigh-in?",
            isPresented: Binding(get: { weighInToDelete != nil }, set: { if !$0 { weighInToDelete = nil } }),
            titleVisibility: .visible,
            presenting: weighInToDelete
        ) { weighIn in
            Button("Delete weigh-in", role: .destructive) {
                Task { await delete(weighIn) }
            }
        } message: { weighIn in
            Text(deleteMessage(weighIn))
        }
        // It replaces numbers the user may have typed, so it asks, as Recalculate does.
        .alert("Switch to Maintain?", isPresented: $isConfirmingMaintain) {
            Button("Switch") { Task { await profileVm.updatePlan(.goal(.maintain, goalWeightKg: nil)) } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This works out new targets for keeping your weight steady, and restarts your plan from today.")
        }
    }

    // MARK: - Parts

    /// The trend is the number that matters. It is an estimate, so it carries the
    /// dotted rule, and stays pending until there are enough weigh-ins.
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Weight")
                .font(.circaTitle)
                .foregroundStyle(Color.circaInk)
            CircaEstimate(trendText, certainty: .estimated, font: .circaMonoLarge)
            Text(caption)
                .font(.circaMono)
                .foregroundStyle(Color.circaInk3)
        }
    }

    /// Says so plainly and changes nothing: the user picks what comes next.
    private func goalNote(_ goalKg: Double) -> some View {
        CircaCard {
            VStack(alignment: .leading, spacing: Circa.Space.rowGap) {
                Text("You've reached your goal weight of \(BodyWeight.displayString(kilograms: goalKg, unit: unit)). Your targets stay as they are until you choose what's next.")
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Switch to Maintain") { isConfirmingMaintain = true }
                    .buttonStyle(.circa(.secondary))
                Button("Set a new goal") { isTargetsPresented = true }
                    .buttonStyle(.circa(.link, height: 32))
            }
        }
    }

    private func weighInList(_ weighIns: [WeighIn]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CircaSectionLabel("Weigh-ins")
                .padding(.horizontal, Circa.Space.screenMargin)

            if let note = listNote(weighIns) {
                Text(note)
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaInk3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Circa.Space.screenMargin)
            }

            if weighIns.isEmpty {
                Text("No weigh-ins in the last \(StatsViewModel.trendWindowDays) days.")
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaInk3)
                    .padding(Circa.Space.screenMargin)
            }

            // Newest first. A weigh-in is a measurement, so its number carries no rule.
            ForEach(weighIns.reversed()) { weighIn in
                let row = CircaEntryRow(
                    title: dayText(weighIn),
                    calories: BodyWeight.displayString(kilograms: weighIn.weightKg, unit: unit),
                    certainty: .known,
                    meta: weighIn.source == .healthKit ? "Apple Health" : "Typed"
                )

                if WeighInDeletion.canDelete(weighIn, among: weighIns) {
                    Button { weighInToDelete = weighIn } label: { row }
                        .buttonStyle(.plain)
                } else {
                    row
                }
            }
        }
        // The rows carry their own margin, as on the Day screen.
        .padding(.horizontal, -Circa.Space.screenMargin)
    }

    // MARK: - Derived

    /// The goal weight, once the trend has got there.
    private var reachedGoalKg: Double? {
        guard let plan, let goalKg = plan.goalWeightKg, viewModel.series.hasTrend,
              let trendKg = viewModel.series.latest?.trendKg, plan.isGoalReached(trendKg: trendKg)
        else { return nil }
        return goalKg
    }

    private var trendText: String? {
        guard viewModel.series.hasTrend, let latest = viewModel.series.latest else { return nil }
        return BodyWeight.displayString(kilograms: latest.trendKg, unit: unit)
    }

    /// Labels the number and states the goal in words, because the chart draws the
    /// goal only when it is close.
    private var caption: String {
        guard let goalKg = plan?.goalWeightKg else { return "Trend" }
        return "Trend · Goal \(BodyWeight.displayString(kilograms: goalKg, unit: unit))"
    }

    private func dayText(_ weighIn: WeighIn) -> String {
        guard let date = DateKey.date(from: weighIn.dateKey) else { return weighIn.dateKey }
        return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    /// Only the lines that apply: how to delete, and why Health rows can't be.
    private func listNote(_ weighIns: [WeighIn]) -> String? {
        var lines: [String] = []
        if weighIns.contains(where: { WeighInDeletion.canDelete($0, among: weighIns) }) {
            lines.append("Tap a typed weigh-in to delete it.")
        }
        if weighIns.contains(where: { $0.source == .healthKit }) {
            lines.append("Weigh-ins from Apple Health can only be changed in the Health app.")
        }
        return lines.isEmpty ? nil : lines.joined(separator: " ")
    }

    /// Names the weigh-in. With Health connected, a Health reading for the same
    /// day takes its place on the next open (decided 19 September), so it says so.
    private func deleteMessage(_ weighIn: WeighIn) -> String {
        let named = "\(dayText(weighIn)) · \(BodyWeight.displayString(kilograms: weighIn.weightKg, unit: unit))"
        guard healthWeightSync.isConnected else { return named }
        return named + ". If Apple Health has a reading for that day, it will show here instead."
    }

    private func delete(_ weighIn: WeighIn) async {
        guard let userId = profileVm.profile?.id,
              let movedWeightKg = await viewModel.delete(weighIn, userId: userId) else { return }
        // In memory, as after a weigh-in; the view model made the durable write.
        profileVm.applyWeighIn(kg: movedWeightKg)
    }
}
