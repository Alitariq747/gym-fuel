//
//  OnboardingGoalWeightStepView.swift
//  GymFuel
//
//  Step 4c — the goal weight, after Gain or Lose fat. Maintain skips it.
//  The wheel offers only weights `SafetyLimits` allows, and opens next to the
//  current weight: nothing in Step 4 suggests a goal. Built from the 2a kit.
//

import SwiftUI

struct OnboardingGoalWeightStepView: View {
    /// Lose fat or Gain. The flow never shows this step for Maintain.
    let goal: GoalType
    let currentWeightKg: Double
    let heightCm: Double
    @Binding var goalWeightKg: Double?
    /// 1-based position in the flow, and its length, as on the reminders step.
    let stepPosition: Int
    let stepCount: Int
    let onNext: () -> Void

    /// Shared with the weigh-in sheet, so picking pounds here carries through.
    @AppStorage(BodyWeightUnit.preferenceKey) private var unitRawValue = BodyWeightUnit.kilograms.rawValue
    /// The one stored value, which the wheel reads and writes in whole units, as in
    /// `EditWeightSheet`, so switching units never drifts. Nil until the wheel moves.
    @State private var selectedKg: Double?
    @State private var isPickerPresented = false
    @ScaledMetric(relativeTo: .body) private var pickerHeight: CGFloat = 170

    private var unit: BodyWeightUnit {
        BodyWeightUnit(rawValue: unitRawValue) ?? .kilograms
    }

    private var options: [Int] {
        SafetyLimits.goalWeightOptions(for: goal, currentWeightKg: currentWeightKg, heightCm: heightCm, unit: unit)
    }

    /// The allowed row nearest the stored value or, before the wheel moves, the
    /// row next to the current weight.
    private var selection: Binding<Int> {
        Binding(
            get: {
                let allowed = options
                guard let selectedKg else { return (goal == .cut ? allowed.last : allowed.first) ?? 0 }
                let target = inUnit(selectedKg)
                return allowed.min { abs(Double($0) - target) < abs(Double($1) - target) } ?? 0
            },
            set: { selectedKg = kilograms($0) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            AdaptiveScrollContainer {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    OnboardingValueCard(value: readingText, label: "Goal weight") {
                        isPickerPresented = true
                    }
                    .disabled(options.isEmpty)
                    if goal == .cut { floorNote }
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.top, 18)
                .padding(.bottom, 12)
            }

            Button(action: next) {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(.circa(.primary, height: 52))
            .disabled(options.isEmpty)
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.bottom, 16)
        }
        .circaPaper()
        .sheet(isPresented: $isPickerPresented) { picker }
        .onAppear {
            // Keep an earlier answer only while it is still allowed: the goal,
            // weight or height may have changed since.
            if let goalWeightKg,
               SafetyLimits.allowsGoalWeight(goalWeightKg, for: goal, currentWeightKg: currentWeightKg, heightCm: heightCm) {
                selectedKg = goalWeightKg
            }
        }
    }

    // MARK: - Parts

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            CircaSectionLabel("About you · \(stepPosition) of \(stepCount)")

            Text("What weight are you aiming for?")
                .font(.circaTitle)
                .foregroundStyle(Color.circaInk)
                .fixedSize(horizontal: false, vertical: true)

            Text("You're \(Int(inUnit(currentWeightKg).rounded())) \(unit.shortLabel) now. Pick the weight your plan heads \(goal == .cut ? "down" : "up") to. You can change it any time.")
                .font(.circaBody)
                .foregroundStyle(Color.circaInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The row the wheel is on. Empty only when no weight is allowed at all,
    /// which also disables Continue.
    private var readingText: String {
        options.isEmpty ? "—" : "\(selection.wrappedValue) \(unit.shortLabel)"
    }

    private var picker: some View {
        OnboardingWheelSheet(title: "Goal weight") {
            UnitToggle(
                options: BodyWeightUnit.allCases,
                label: { $0.shortLabel },
                selection: $unitRawValue.asBodyWeightUnit
            )
        } wheel: {
            Picker("Goal weight", selection: selection) {
                ForEach(options, id: \.self) { value in
                    Text("\(value)").font(.circaMonoValue).tag(value)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(height: pickerHeight)
            .clipped()
            .accessibilityValue(readingText)
        }
    }

    /// Why the wheel stops where it does, unless the app's own lowest weight,
    /// not the healthy range, is what stops it.
    @ViewBuilder
    private var floorNote: some View {
        let floorKg = SafetyLimits.weightKg(atBMI: SafetyLimits.underweightBMI, heightCm: heightCm)
        if floorKg >= BodyWeight.minimumKilograms, let lowest = options.first {
            Text("The wheel stops at \(lowest) \(unit.shortLabel). Anything lower is under the healthy range for your height.")
                .font(.circaCaption)
                .foregroundStyle(Color.circaInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Actions and units

    /// Saves the row on screen, so what was shown is what is stored.
    private func next() {
        guard !options.isEmpty else { return }
        goalWeightKg = BodyWeight.roundedForStorage(kilograms(selection.wrappedValue))
        onNext()
    }

    private func inUnit(_ kg: Double) -> Double {
        unit == .kilograms ? kg : BodyWeight.pounds(fromKilograms: kg)
    }

    private func kilograms(_ value: Int) -> Double {
        unit == .kilograms ? Double(value) : BodyWeight.kilograms(fromPounds: Double(value))
    }
}

#Preview("Goal weight · Lose fat") {
    OnboardingGoalWeightStepView(goal: .cut, currentWeightKg: 85, heightCm: 175, goalWeightKg: .constant(nil), stepPosition: 11, stepCount: 14, onNext: {})
}

#Preview("Goal weight · Gain · dark") {
    OnboardingGoalWeightStepView(goal: .leanBulk, currentWeightKg: 70, heightCm: 178, goalWeightKg: .constant(nil), stepPosition: 11, stepCount: 14, onNext: {})
        .preferredColorScheme(.dark)
}
