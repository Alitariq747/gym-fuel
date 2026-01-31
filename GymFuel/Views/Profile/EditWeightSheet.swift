//
//  EditWeightSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 31/01/2026.
//

import SwiftUI

private enum WeightEditUnit: String, CaseIterable {
    case kilograms
    case pounds
}

/// Edit: Update the user's weight (stored in kilograms).
struct EditWeightSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var weightKg: Double?

    @State private var selectedUnit: WeightEditUnit = .kilograms

    @State private var selectedKg: Int = 75
    @State private var selectedLbs: Int = 165

    @State private var errorMessage: String?
    @State private var didInitialize = false

    private let kgRange = Array(30...200)
    private let lbsRange = Array(66...440)

    var body: some View {
        VStack(spacing: 20) {
            header

            WeightUnitSegmentedControl(selectedUnit: $selectedUnit)

            summaryCard
            inputCard

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss()
                } label: {
                    Image(systemName: "x.circle.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color(.systemGray3))

                }
                .buttonStyle(.plain)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    handleDone()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(.systemGray3))
                }
                .buttonStyle(.plain)
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

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "scalemass")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.top, 4)

            Text("Update your weight to keep your macros and fueling targets accurate.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 6) {
            Text(primaryWeightText)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text(secondaryWeightText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedUnit == .kilograms ? "Weight (kg)" : "Weight (lbs)")
                .font(.headline)

            if selectedUnit == .kilograms {
                Picker("Kilograms", selection: $selectedKg) {
                    ForEach(kgRange, id: \.self) { kg in
                        Text("\(kg) kg").tag(kg)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 160)
                .clipped()
                .labelsHidden()
            } else {
                Picker("Pounds", selection: $selectedLbs) {
                    ForEach(lbsRange, id: \.self) { lbs in
                        Text("\(lbs) lbs").tag(lbs)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 160)
                .clipped()
                .labelsHidden()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
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

    // MARK: - Done

    private func handleDone() {
        let kg = computedWeightKg
        guard kg > 0 else {
            errorMessage = "Please select a valid weight."
            return
        }
        errorMessage = nil
        weightKg = kg
        dismiss()
    }
}

private struct WeightUnitSegmentedControl: View {
    @Binding var selectedUnit: WeightEditUnit

    var body: some View {
        HStack(spacing: 0) {
            segment(title: "kg", unit: .kilograms)
            segment(title: "lbs", unit: .pounds)
        }
        .padding(4)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func segment(title: String, unit: WeightEditUnit) -> some View {
        let isSelected = (selectedUnit == unit)

        return Button {
            selectedUnit = unit
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color(.systemBackground) : Color(.secondarySystemBackground))
                )
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    EditWeightSheet(weightKg: .constant(83))
}
