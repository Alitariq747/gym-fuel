//
//  EditHeightSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 29/01/2026.
//

import SwiftUI


private enum HeightUnit: String, CaseIterable {
    case centimeters
    case feetInches
}

struct EditHeightSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var heightCm: Double?

    @State private var selectedUnit: HeightUnit = .centimeters

    // Picker-backed state (same idea as onboarding)
    @State private var selectedCm: Int = 175
    @State private var selectedFeet: Int = 5
    @State private var selectedInches: Int = 9

    @State private var errorMessage: String?
    @State private var didInitialize = false

    private let cmRange = Array(120...220)
    private let feetRange = Array(3...8)
    private let inchRange = Array(0...11)

    var body: some View {
        VStack(spacing: 16) {
            header

            HeightUnitSegmentedControl(selectedUnit: $selectedUnit)

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
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("Height")
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
        .onChange(of: selectedCm) { _, newValue in
            guard selectedUnit == .centimeters else { return }
            syncFeetInchesFromCm(Double(newValue))
        }
        .onChange(of: selectedFeet) { _, _ in
            guard selectedUnit == .feetInches else { return }
            syncCmFromFeetInches()
        }
        .onChange(of: selectedInches) { _, _ in
            guard selectedUnit == .feetInches else { return }
            syncCmFromFeetInches()
        }
    }

    // MARK: - UI Pieces (matches onboarding styling)
    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "ruler")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.top, 4)

            Text("Update your height. We store it in centimeters, but you can enter it in either unit.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 6) {
            Text(primaryHeightText)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text(secondaryHeightText)
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
            Text(selectedUnit == .centimeters ? "Height (cm)" : "Height (ft / in)")
                .font(.headline)

            if selectedUnit == .centimeters {
                Picker("Centimeters", selection: $selectedCm) {
                    ForEach(cmRange, id: \.self) { cm in
                        Text("\(cm) cm").tag(cm)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 160)
                .clipped()
                .labelsHidden()
            } else {
                HStack(spacing: 12) {
                    Picker("Feet", selection: $selectedFeet) {
                        ForEach(feetRange, id: \.self) { ft in
                            Text("\(ft) ft").tag(ft)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipped()
                    .labelsHidden()

                    Picker("Inches", selection: $selectedInches) {
                        ForEach(inchRange, id: \.self) { inch in
                            Text("\(inch) in").tag(inch)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipped()
                    .labelsHidden()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Derived Text (same logic as onboarding)
    private var computedHeightCm: Double {
        switch selectedUnit {
        case .centimeters:
            return Double(selectedCm)
        case .feetInches:
            let totalInches = Double(selectedFeet * 12 + selectedInches)
            return totalInches * 2.54
        }
    }

    private var primaryHeightText: String {
        switch selectedUnit {
        case .centimeters:
            return "\(selectedCm) cm"
        case .feetInches:
            return "\(selectedFeet)′ \(selectedInches)″"
        }
    }

    private var secondaryHeightText: String {
        let cm = computedHeightCm
        let totalInches = cm / 2.54
        let ft = Int(totalInches / 12.0)
        let inch = Int((totalInches.truncatingRemainder(dividingBy: 12.0)).rounded())

        if selectedUnit == .centimeters {
            return "≈ \(ft)′ \(inch)″"
        } else {
            return "≈ \(Int(cm.rounded())) cm"
        }
    }

    // MARK: - Init / Sync (same idea as onboarding)
    private func initializeFromBindingIfNeeded() {
        guard !didInitialize else { return }
        didInitialize = true

        if let existing = heightCm, existing > 0 {
            let cm = Int(existing.rounded())
            selectedCm = min(max(cm, cmRange.first ?? cm), cmRange.last ?? cm)
            syncFeetInchesFromCm(existing)
        } else {
            syncFeetInchesFromCm(Double(selectedCm))
        }
    }

    private func syncPickersForUnitSwitch() {
        if selectedUnit == .centimeters {
            syncCmFromFeetInches()
        } else {
            syncFeetInchesFromCm(Double(selectedCm))
        }
    }

    private func syncFeetInchesFromCm(_ cm: Double) {
        let totalInches = cm / 2.54
        let ft = Int(totalInches / 12.0)
        let inch = Int((totalInches.truncatingRemainder(dividingBy: 12.0)).rounded())

        selectedFeet = min(max(ft, feetRange.first ?? ft), feetRange.last ?? ft)
        selectedInches = min(max(inch, inchRange.first ?? inch), inchRange.last ?? inch)
    }

    private func syncCmFromFeetInches() {
        let totalInches = Double(selectedFeet * 12 + selectedInches)
        let cm = Int((totalInches * 2.54).rounded())
        selectedCm = min(max(cm, cmRange.first ?? cm), cmRange.last ?? cm)
    }

    // MARK: - Done
    private func handleDone() {
        let cm = computedHeightCm
        guard cm > 0 else {
            errorMessage = "Please select a valid height."
            return
        }
        errorMessage = nil
        heightCm = cm
        dismiss()
    }
}

private struct HeightUnitSegmentedControl: View {
    @Binding var selectedUnit: HeightUnit

    var body: some View {
        HStack(spacing: 0) {
            segment(title: "cm", unit: .centimeters)
            segment(title: "ft / in", unit: .feetInches)
        }
        .padding(4)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func segment(title: String, unit: HeightUnit) -> some View {
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
    EditHeightSheet(heightCm: .constant(175))
}
