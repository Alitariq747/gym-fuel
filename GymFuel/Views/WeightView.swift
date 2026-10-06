//
//  WeightView.swift
//  GymFuel
//

import SwiftUI

/// The user's weigh-ins against their goal. Opens from the Week card until 7
/// puts it in the menu.
///
/// **Nothing here judges.** No red, no "behind", no advice: the chart shows the
/// weigh-ins and the goal, and the user reads the distance.
struct WeightView: View {
    @EnvironmentObject private var profileVm: UserProfileViewModel
    @EnvironmentObject private var healthWeightSync: HealthWeightSyncService
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(BodyWeightUnit.preferenceKey) private var unitRawValue = BodyWeightUnit.kilograms.rawValue
    @StateObject private var viewModel = WeightViewModel()
    @State private var isTargetsPresented = false
    @State private var isWeighInPresented = false
    @State private var chartRange: WeightChartRange = .ninetyDays
    @State private var isConfirmingMaintain = false
    @State private var weighInToDelete: WeighIn?

    private var unit: BodyWeightUnit {
        BodyWeightUnit(rawValue: unitRawValue) ?? .kilograms
    }

    /// Read from the live profile, so a goal changed on the targets screen redraws
    /// the goal the moment it saves.
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
                    VStack(alignment: .leading, spacing: Circa.Space.rowGap) {
                        UnitToggle(options: WeightChartRange.allCases, label: { $0.title }, selection: $chartRange)
                        WeightChart(
                            series: viewModel.series,
                            unit: unit,
                            domain: chartRange.domain(firstWeighIn: viewModel.series.points.first?.date),
                            goalKg: plan?.goalWeightKg
                        )
                    }
                }

                if let goalKg = plan?.goalWeightKg, let latest = viewModel.series.latest,
                   let remainingKg = plan?.remainingKg(from: latest.weightKg) {
                    goalCard(goalKg: goalKg, remainingKg: remainingKg)
                }

                if let message = viewModel.errorMessage ?? profileVm.errorMessage {
                    Text(message)
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaDanger)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button { isWeighInPresented = true } label: {
                    Text("Weigh in").frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary))

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
        .sheet(isPresented: $isWeighInPresented) {
            EditWeightSheet(
                userId: profileVm.profile?.id ?? "",
                initialWeightKg: viewModel.series.latest?.weightKg ?? profileVm.profile?.weightKg,
                onWeighIn: { kg in
                    profileVm.applyWeighIn(kg: kg)
                    Task { await viewModel.load(userId: profileVm.profile?.id ?? "") }
                }
            )
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

    /// The last weigh-in, as the scale said it. A measurement, so no dotted rule.
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Weight")
                .font(.circaTitle)
                .foregroundStyle(Color.circaInk)
            if let latest = viewModel.series.latest {
                Text(BodyWeight.displayString(kilograms: latest.weightKg, unit: unit))
                    .font(.circaMonoLarge)
                    .monospacedDigit()
                    .foregroundStyle(Color.circaInk)
                Text("Last weigh-in · \(latest.date.formatted(.dateTime.day().month(.abbreviated).year()))")
                    .font(.circaMono)
                    .foregroundStyle(Color.circaInk3)
            }
        }
    }

    private func goalCard(goalKg: Double, remainingKg: Double) -> some View {
        CircaCard {
            VStack(alignment: .leading, spacing: 4) {
                CircaSectionLabel("Goal")
                Text(BodyWeight.displayString(kilograms: goalKg, unit: unit))
                    .font(.circaMonoLarge)
                    .monospacedDigit()
                    .foregroundStyle(Color.circaInk)
                Text("\(BodyWeight.displayString(kilograms: remainingKg, unit: unit)) to go")
                    .font(.circaMono)
                    .foregroundStyle(Color.circaInk3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
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
                Text("No weigh-ins yet.")
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

    /// The goal weight, once the last weigh-in has got there.
    private var reachedGoalKg: Double? {
        guard let plan, let goalKg = plan.goalWeightKg,
              let latest = viewModel.series.latest, plan.isGoalReached(weightKg: latest.weightKg)
        else { return nil }
        return goalKg
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
