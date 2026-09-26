//
//  OnboardingHeightStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

struct OnboardingHeightStepView: View {
    @Binding var heightCm: Double?
    let onNext: () -> Void

    @ScaledMetric(relativeTo: .body) private var pickerHeight: CGFloat = 170

    @State private var selectedUnit: BodyHeightUnit = .centimeters
    /// Centimetres are the one stored value; feet and inches are a view on it
    /// through `HeightWheel`.
    @State private var selectedCm: Int = 175
    @State private var isPickerPresented = false
    @State private var didInitialize = false

    private var wheel: HeightWheel { HeightWheel(selectedUnit) }

    var body: some View {
        OnboardingMetricPage(title: "How tall are you?", onContinue: handleNext) {
            OnboardingValueCard(value: wheel.displayString(selectedCm), label: "Height") {
                isPickerPresented = true
            }
        }
        .sheet(isPresented: $isPickerPresented) { picker }
        .onAppear { initializeFromBindingIfNeeded() }
    }

    // MARK: - The sheet

    private var picker: some View {
        OnboardingWheelSheet(title: "Your height") {
            UnitToggle(
                options: BodyHeightUnit.allCases,
                label: { $0.shortLabel },
                selection: $selectedUnit
            )
        } wheel: {
            Group {
                if selectedUnit == .centimeters {
                    Picker("Centimetres", selection: $selectedCm) {
                        ForEach(wheel.centimeterRange, id: \.self) { cm in
                            Text("\(cm) cm").font(.circaMonoValue).tag(cm)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                } else {
                    HStack(spacing: 0) {
                        Picker("Feet", selection: feet) {
                            ForEach(wheel.feetRange, id: \.self) { value in
                                Text("\(value)′").font(.circaMonoValue).tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)

                        Picker("Inches", selection: inches) {
                            ForEach(wheel.inchRange(atFeet: feet.wrappedValue), id: \.self) { value in
                                Text("\(value)″").font(.circaMonoValue).tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: pickerHeight)
            .clipped()
        }
    }

    // MARK: - Wheels

    private var feet: Binding<Int> {
        Binding(
            get: { wheel.feetInches(selectedCm).feet },
            set: { selectedCm = wheel.centimeters(feet: $0, inches: wheel.feetInches(selectedCm).inches) }
        )
    }

    private var inches: Binding<Int> {
        Binding(
            get: { wheel.feetInches(selectedCm).inches },
            set: { selectedCm = wheel.centimeters(feet: wheel.feetInches(selectedCm).feet, inches: $0) }
        )
    }

    // MARK: - Init and next

    private func initializeFromBindingIfNeeded() {
        guard !didInitialize else { return }
        didInitialize = true

        if let existing = heightCm, existing > 0 {
            selectedCm = wheel.clamped(Int(existing.rounded()))
        }
    }

    private func handleNext() {
        heightCm = Double(selectedCm)
        onNext()
    }
}

#Preview {
    NavigationStack {
        OnboardingHeightStepView(heightCm: .constant(175), onNext: {})
    }
}

#Preview("Dark") {
    NavigationStack {
        OnboardingHeightStepView(heightCm: .constant(170), onNext: {})
    }
    .preferredColorScheme(.dark)
}
