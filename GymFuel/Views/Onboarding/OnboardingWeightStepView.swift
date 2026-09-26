//
//  OnboardingWeightStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

/// Step: Ask for the user's weight (stored in kilograms).
///
/// Records tenths, not whole units. This answer is seeded as day zero of the
/// trend (`UserProfileViewModel.seedFirstWeighIn`), and a whole-kilogram seed
/// cannot sit on the same scale as the 0.1 weigh-ins that follow it.
struct OnboardingWeightStepView: View {
    @Binding var weightKg: Double?
    let onNext: () -> Void

    @ScaledMetric(relativeTo: .body) private var pickerHeight: CGFloat = 170

    /// Shared with the weigh-in sheet and the goal weight step, so choosing
    /// pounds here carries through instead of being asked again next step.
    @AppStorage(BodyWeightUnit.preferenceKey) private var unitRawValue = BodyWeightUnit.kilograms.rawValue

    /// The one stored value; both wheels read and write it through `WeightWheel`.
    @State private var enteredKg: Double = 75
    @State private var isPickerPresented = false
    @State private var didInitialize = false

    private var unit: BodyWeightUnit {
        BodyWeightUnit(rawValue: unitRawValue) ?? .kilograms
    }

    private var wheel: WeightWheel { WeightWheel(unit) }

    var body: some View {
        OnboardingMetricPage(
            title: "What do you weigh?",
            detail: "Weights after this one come from weigh-ins, so the trend stays a measurement.",
            onContinue: handleNext
        ) {
            OnboardingValueCard(value: weightText, label: "Weight") {
                isPickerPresented = true
            }
        }
        .sheet(isPresented: $isPickerPresented) { picker }
        .onAppear { initializeFromBindingIfNeeded() }
        // The two wheels step differently, so the same weight is not on a row in
        // both units. Snap, or the card and the wheel disagree.
        .onChange(of: unitRawValue) { _, _ in enteredKg = wheel.snapped(enteredKg) }
    }

    // MARK: - The sheet

    private var picker: some View {
        OnboardingWheelSheet(title: "Your weight") {
            UnitToggle(
                options: BodyWeightUnit.allCases,
                label: { $0.shortLabel },
                selection: $unitRawValue.asBodyWeightUnit
            )
        } wheel: {
            HStack(spacing: 0) {
                Picker("", selection: whole) {
                    ForEach(wheel.wholeRange, id: \.self) { value in
                        Text("\(value)").font(.circaMonoValue).tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(unit == .kilograms ? "Kilograms" : "Pounds")

                Picker("", selection: tenth) {
                    ForEach(wheel.tenthRange, id: \.self) { value in
                        Text(".\(value)").font(.circaMonoValue).tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Decimal")
            }
            .frame(height: pickerHeight)
            .labelsHidden()
            .clipped()
        }
    }

    // MARK: - Wheels

    private var whole: Binding<Int> {
        Binding(
            get: { wheel.digits(enteredKg).whole },
            set: { enteredKg = wheel.kilograms(whole: $0, tenth: wheel.digits(enteredKg).tenth) }
        )
    }

    private var tenth: Binding<Int> {
        Binding(
            get: { wheel.digits(enteredKg).tenth },
            set: { enteredKg = wheel.kilograms(whole: wheel.digits(enteredKg).whole, tenth: $0) }
        )
    }

    private var weightText: String {
        BodyWeight.displayString(kilograms: enteredKg, unit: unit)
    }

    // MARK: - Init and next

    private func initializeFromBindingIfNeeded() {
        guard !didInitialize else { return }
        didInitialize = true

        if let existing = weightKg, existing > 0 {
            enteredKg = wheel.snapped(existing)
        }
    }

    private func handleNext() {
        weightKg = BodyWeight.roundedForStorage(enteredKg)
        onNext()
    }
}

#Preview {
    NavigationStack {
        OnboardingWeightStepView(weightKg: .constant(78.5), onNext: {})
    }
}

#Preview("Dark") {
    NavigationStack {
        OnboardingWeightStepView(weightKg: .constant(83), onNext: {})
    }
    .preferredColorScheme(.dark)
}
