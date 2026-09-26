//
//  EditHeightSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 29/01/2026.
//

import SwiftUI

struct EditHeightSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var heightCm: Double?
    @ScaledMetric(relativeTo: .body) private var pickerHeight: CGFloat = 160

    @State private var selectedUnit: BodyHeightUnit = .centimeters
    /// Centimetres are the one stored value; feet and inches are a view on it
    /// through `HeightWheel`.
    @State private var selectedCm: Int = 175
    @State private var didInitialize = false

    private var wheel: HeightWheel { HeightWheel(selectedUnit) }

    var body: some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 20) {
                header

                UnitToggle(
                    options: BodyHeightUnit.allCases,
                    label: { $0.shortLabel },
                    selection: $selectedUnit
                )

                summaryCard
                inputCard
            }
            .padding(Circa.Space.screenMargin)
        }
        .circaPaper()
        .navigationTitle("Height")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Color.circaInk2)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done", action: handleDone)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.circaAccent)
            }
        }
        .onAppear { initializeFromBindingIfNeeded() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            CircaSectionLabel("About you")
            Text("Your height")
                .font(.circaTitle)
                .foregroundStyle(Color.circaInk)
            Text("Update your height. We store it in centimeters, but you can enter it in either unit.")
                .font(.circaBody)
                .foregroundStyle(Color.circaInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 6) {
            CircaSectionLabel("Selected height")
            Text(wheel.displayString(selectedCm))
                .font(.circaMonoLarge)
                .foregroundStyle(Color.circaInk)

            Text(otherUnitText)
                .font(.circaCaption)
                .foregroundStyle(Color.circaInk2)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Color.circaCard, in: RoundedRectangle(cornerRadius: Circa.Radius.cardSmall))
        .overlay {
            RoundedRectangle(cornerRadius: Circa.Radius.cardSmall)
                .strokeBorder(Color.circaCardBorder, lineWidth: 1)
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            CircaSectionLabel(selectedUnit == .centimeters ? "Height (cm)" : "Height (ft / in)")

            Group {
                if selectedUnit == .centimeters {
                    Picker("Centimetres", selection: $selectedCm) {
                        ForEach(wheel.centimeterRange, id: \.self) { cm in
                            Text("\(cm) cm").tag(cm)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                } else {
                    HStack(spacing: 12) {
                        Picker("Feet", selection: feet) {
                            ForEach(wheel.feetRange, id: \.self) { value in
                                Text("\(value) ft").tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)

                        Picker("Inches", selection: inches) {
                            ForEach(wheel.inchRange(atFeet: feet.wrappedValue), id: \.self) { value in
                                Text("\(value) in").tag(value)
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
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color.circaCard, in: RoundedRectangle(cornerRadius: Circa.Radius.cardSmall))
        .overlay {
            RoundedRectangle(cornerRadius: Circa.Radius.cardSmall)
                .strokeBorder(Color.circaCardBorder, lineWidth: 1)
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

    private var otherUnitText: String {
        let other: BodyHeightUnit = selectedUnit == .centimeters ? .feetInches : .centimeters
        return "≈ " + HeightWheel(other).displayString(selectedCm)
    }

    // MARK: - Init and done

    private func initializeFromBindingIfNeeded() {
        guard !didInitialize else { return }
        didInitialize = true

        if let existing = heightCm, existing > 0 {
            selectedCm = wheel.clamped(Int(existing.rounded()))
        }
    }

    private func handleDone() {
        heightCm = Double(selectedCm)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        EditHeightSheet(heightCm: .constant(175))
    }
}
