//
//  OnboardingWeightStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

private enum WeightUnit: String, CaseIterable {
    case kilograms
    case pounds
}

/// Step: Ask for the user's weight (stored in kilograms).
struct OnboardingWeightStepView: View {
    @Binding var weightKg: Double?
    let onNext: () -> Void

    @ScaledMetric(relativeTo: .body) private var pickerHeight: CGFloat = 160

    @State private var selectedUnit: WeightUnit = .kilograms

   
    @State private var selectedKg: Int = 75
    @State private var selectedLbs: Int = 165

    @State private var errorMessage: String?
    @State private var didInitialize = false

   
    private let kgRange = Array(30...200)
    private let lbsRange = Array(66...440)

    var body: some View {
        OnboardingMetricPage(
            title: "What do you weigh?",
            detail: "Your starting weight sets the plan. Future weights come from weigh-ins, so the trend stays meaningful.",
            onContinue: handleNext
        ) {
            VStack(alignment: .leading, spacing: 18) {
                UnitSegmentedControl(selectedUnit: $selectedUnit)
                summaryCard
                inputCard

                if let errorMessage {
                    Text(errorMessage)
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaDanger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .onAppear { initializeFromBindingIfNeeded() }
        .onChange(of: selectedUnit) { _, _ in syncPickersForUnitSwitch() }
        .onChange(of: selectedKg) { _, newValue in
            guard selectedUnit == .kilograms else { return }
            syncLbsFromKg(Double(newValue))
        }
        .onChange(of: selectedLbs) { _, _ in
            guard selectedUnit == .pounds else { return }
            syncKgFromLbs()
        }
    }

    // MARK: - UI

    private var summaryCard: some View {
        VStack(spacing: 6) {
            Text(primaryWeightText)
                .font(.system(.largeTitle, design: .monospaced).weight(.semibold))
                .foregroundStyle(Color.circaInk)
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)

            Text(secondaryWeightText)
                .font(.circaMono)
                .foregroundStyle(Color.circaInk2)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Color.circaCard, in: RoundedRectangle(cornerRadius: Circa.Radius.cardSmall))
        .overlay {
            RoundedRectangle(cornerRadius: Circa.Radius.cardSmall)
                .strokeBorder(Color.circaCardBorder, lineWidth: Circa.Rule.hairline)
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedUnit == .kilograms ? "Weight (kg)" : "Weight (lbs)")
                .font(.circaRow)
                .foregroundStyle(Color.circaInk2)

            if selectedUnit == .kilograms {
                Picker("Kilograms", selection: $selectedKg) {
                    ForEach(kgRange, id: \.self) { kg in
                        Text("\(kg) kg").tag(kg)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: pickerHeight)
                .clipped()
                .labelsHidden()
            } else {
                Picker("Pounds", selection: $selectedLbs) {
                    ForEach(lbsRange, id: \.self) { lbs in
                        Text("\(lbs) lbs").tag(lbs)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: pickerHeight)
                .clipped()
                .labelsHidden()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.circaCard, in: RoundedRectangle(cornerRadius: Circa.Radius.cardSmall))
        .overlay {
            RoundedRectangle(cornerRadius: Circa.Radius.cardSmall)
                .strokeBorder(Color.circaCardBorder, lineWidth: Circa.Rule.hairline)
        }
    }

    // MARK: - Derived values

    private var computedWeightKg: Double {
        switch selectedUnit {
        case .kilograms:
            return Double(selectedKg)
        case .pounds:
            return Double(selectedLbs) * 0.45359237
        }
    }

    private var primaryWeightText: String {
        switch selectedUnit {
        case .kilograms:
            return "\(selectedKg) kg"
        case .pounds:
            return "\(selectedLbs) lbs"
        }
    }

    private var secondaryWeightText: String {
        let kg = computedWeightKg
        let lbs = kg / 0.45359237

        if selectedUnit == .kilograms {
            return "≈ \(Int(lbs.rounded())) lbs"
        } else {
            return "≈ \(Int(kg.rounded())) kg"
        }
    }

    // MARK: - Init / Sync

    private func initializeFromBindingIfNeeded() {
        guard !didInitialize else { return }
        didInitialize = true

        if let existing = weightKg, existing > 0 {
            let kg = Int(existing.rounded())
            selectedKg = min(max(kg, kgRange.first ?? kg), kgRange.last ?? kg)
            syncLbsFromKg(existing)
        } else {
            syncLbsFromKg(Double(selectedKg))
        }
    }

    private func syncPickersForUnitSwitch() {
        if selectedUnit == .kilograms {
            syncKgFromLbs()
        } else {
            syncLbsFromKg(Double(selectedKg))
        }
    }

    private func syncLbsFromKg(_ kg: Double) {
        let lbs = Int((kg / 0.45359237).rounded())
        selectedLbs = min(max(lbs, lbsRange.first ?? lbs), lbsRange.last ?? lbs)
    }

    private func syncKgFromLbs() {
        let kg = Int((Double(selectedLbs) * 0.45359237).rounded())
        selectedKg = min(max(kg, kgRange.first ?? kg), kgRange.last ?? kg)
    }

    // MARK: - Next

    private func handleNext() {
        let kg = computedWeightKg
        guard kg > 0 else {
            errorMessage = "Please select a valid weight."
            return
        }
        errorMessage = nil
        weightKg = kg
        onNext()
    }
}

private struct UnitSegmentedControl: View {
    @Binding var selectedUnit: WeightUnit

    var body: some View {
        HStack(spacing: 0) {
            segment(title: "kg", unit: .kilograms)
            segment(title: "lbs", unit: .pounds)
        }
        .padding(4)
        .background(Color.circaSunken, in: RoundedRectangle(cornerRadius: Circa.Radius.button))
        
    }

    private func segment(title: String, unit: WeightUnit) -> some View {
        let isSelected = (selectedUnit == unit)

        return Button {
            selectedUnit = unit
        } label: {
            Text(title)
                .font(.circaRow.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: Circa.minHitTarget)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(isSelected ? Color.circaCard : Color.clear)
                )
                .foregroundStyle(isSelected ? Color.circaInk : Color.circaInk2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        OnboardingWeightStepView(weightKg: .constant(78.5), onNext: {})
    }
}
