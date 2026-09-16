//
//  CheckInView.swift
//  GymFuel
//

import SwiftUI

/// The weekly check-in: one sentence about the pace, what it was read from, and
/// a choice when there is one.
///
/// Built in Circa. No colour carries meaning here (`design.md` rule 5): the food
/// log is plain context, and a suggested change is offered, never announced.
struct CheckInView: View {
    let userId: String
    let profile: UserProfile
    let phase: Phase?
    let dueDateKey: String
    @ObservedObject var viewModel: CheckInViewModel
    /// Applies a saved answer to the phase in memory.
    let onDecision: (PhaseDecisionUpdate) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage(BodyWeightUnit.preferenceKey) private var weightUnitRawValue = BodyWeightUnit.kilograms.rawValue
    @State private var isSourcesPresented = false

    private var copy: CheckInCopy {
        CheckInCopy(unit: BodyWeightUnit(rawValue: weightUnitRawValue) ?? .kilograms)
    }

    private var isAccepted: Bool {
        viewModel.saved?.response == .accepted
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    if let evaluation = viewModel.evaluation {
                        Text(copy.sentence(
                            for: evaluation.result,
                            phase: evaluation.phase,
                            currentCalories: evaluation.targetsBefore.calories,
                            accepted: isAccepted
                        ))
                        .font(.circaBody)
                        .foregroundStyle(Color.circaInk)
                        .fixedSize(horizontal: false, vertical: true)

                        if case .step = evaluation.result, let after = evaluation.targetsAfter {
                            targets(before: evaluation.targetsBefore, after: after)
                        }

                        readings(evaluation)
                    } else if viewModel.isEvaluating {
                        ProgressView()
                            .tint(Color.circaInk3)
                            .frame(maxWidth: .infinity)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.circaCaption)
                            .foregroundStyle(Color.circaDanger)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button("How the check-in works") { isSourcesPresented = true }
                        .buttonStyle(.circa(.link, height: 32))
                        .padding(.leading, -10)
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.top, 24)
                .padding(.bottom, 12)
            }

            footer
        }
        .circaPaper()
        .task(id: phase) {
            guard let phase else { return }
            await viewModel.evaluate(userId: userId, profile: profile, phase: phase, dueDateKey: dueDateKey)
        }
        .sheet(isPresented: $isSourcesPresented) {
            NutritionSourcesView()
        }
    }

    // MARK: - Parts

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            CircaSectionLabel("Check-in · \(dueDateLabel)")
            Text("How your pace is going")
                .font(.circaTitle)
                .foregroundStyle(Color.circaInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Today's target and the suggested one. After **Use**, "Before" and "Now".
    private func targets(before: Macros, after: Macros) -> some View {
        CircaCard {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 14))

            layout {
                targetColumn(isAccepted ? "Before" : "Now", before)
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: "arrow.forward")
                        .font(.circaMono)
                        .foregroundStyle(Color.circaInk3)
                        .padding(.top, 22)
                        .accessibilityHidden(true)
                }
                targetColumn(isAccepted ? "Now" : "Suggested", after)
            }
        }
    }

    private func targetColumn(_ label: String, _ macros: Macros) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            CircaSectionLabel(label)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(copy.calories(macros.calories))
                    .font(.circaMonoLarge)
                    .monospacedDigit()
                    .foregroundStyle(Color.circaInk)
                Text("kcal")
                    .font(.circaMono)
                    .foregroundStyle(Color.circaInk3)
            }
            Text("\(Int(macros.protein))P \(Int(macros.carbs))C \(Int(macros.fat))F")
                .font(.circaMono)
                .monospacedDigit()
                .foregroundStyle(Color.circaInk3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// What the pace was read from. Plain context — never coloured, never scored.
    private func readings(_ evaluation: CheckInViewModel.Evaluation) -> some View {
        CircaCard {
            VStack(alignment: .leading, spacing: Circa.Space.rowGap) {
                if let reading = evaluation.result.reading {
                    row("Your pace", copy.weeklyPace(reading.paceKgPerWeek))
                    if evaluation.phase.goalType != .maintain {
                        row("Goal pace", copy.weeklyPace(reading.goalKgPerWeek))
                    }
                    row("Weigh-ins", "\(reading.weighInCount) in \(reading.windowDays) days")
                    CircaHairline(weight: .inCard)
                }
                row("Days logged", "\(evaluation.context.loggedDays) of \(evaluation.contextWindowDays)")
                row(
                    "Average on logged days",
                    evaluation.context.loggedDays > 0
                        ? "\(copy.calories(evaluation.context.averageLoggedCalories)) kcal"
                        : "—"
                )
            }
        }
    }

    @ViewBuilder
    private func row(_ label: String, _ value: String) -> some View {
        let labelText = Text(label)
            .font(.circaRow)
            .foregroundStyle(Color.circaInk2)
        let valueText = Text(value)
            .font(.circaMono)
            .monospacedDigit()
            .foregroundStyle(Color.circaInk)

        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // design.md rule 8: right-aligned numbers beside wrapping text
                // break at accessibility sizes, so the row goes vertical.
                VStack(alignment: .leading, spacing: 2) {
                    labelText
                    valueText
                }
            } else {
                HStack(alignment: .firstTextBaseline) {
                    labelText
                    Spacer(minLength: 8)
                    valueText
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var footer: some View {
        VStack(spacing: 10) {
            if viewModel.saved != nil || (viewModel.evaluation == nil && !viewModel.isEvaluating) {
                Button { dismiss() } label: {
                    Text("Done").frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary, height: 52))
            } else if let evaluation = viewModel.evaluation,
                      case .step = evaluation.result,
                      let after = evaluation.targetsAfter {
                Button { Task { await answer(.accepted) } } label: {
                    Text("Use \(copy.calories(after.calories)) kcal").frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary, height: 52))

                Button { Task { await answer(.rejected) } } label: {
                    Text("Keep my target").frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.secondary, height: 52))
            } else {
                Button { Task { await answer(.acknowledged) } } label: {
                    Text("Done").frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary, height: 52))
            }
        }
        .disabled(viewModel.isSaving || viewModel.isEvaluating)
        .padding(.horizontal, Circa.Space.screenMargin)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Actions

    private func answer(_ response: CheckIn.Response) async {
        guard let answer = await viewModel.answer(response, userId: userId, currentPhase: phase) else { return }
        if let update = answer.phaseUpdate {
            onDecision(update)
        }
        // After **Use** the sheet stays to show the new target; anything else
        // is finished.
        if answer.checkIn.response != .accepted {
            dismiss()
        }
    }

    private var dueDateLabel: String {
        DateKey.date(from: dueDateKey)
            .map { $0.formatted(.dateTime.month(.abbreviated).day()) }
            ?? dueDateKey
    }
}
