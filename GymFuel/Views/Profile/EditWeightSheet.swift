//
//  EditWeightSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 31/01/2026.
//

import SwiftUI

/// Records a weigh-in. **The only way weight enters the app after onboarding.**
///
/// Two properties this screen has to hold, and the reasons they are not
/// negotiable:
///
/// - **0.1 precision.** The trend is an exponential moving average over these
///   values. At whole-kilogram resolution it cannot represent a 0.3 kg week, so
///   the line would be noise rather than a direction.
/// - **One source of truth.** `enteredKg` is the only stored value; both wheels
///   read and write it through computed bindings. The previous version kept two
///   integer pickers in sync with each other through a pair of `onChange`
///   handlers, which was merely lossy at whole kilograms and would drift at
///   tenths.
struct EditWeightSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// The account the weigh-in belongs to.
    let userId: String
    /// Called with the saved weight so the caller can reflect it without a refetch.
    let onWeighIn: (Double) -> Void

    @StateObject private var viewModel = WeighInViewModel()

    /// Persisted, unlike the old `@State`. A weigh-in is meant to be weekly or
    /// better; making a pounds user re-pick pounds every time is friction on the
    /// exact loop the trend depends on.
    @AppStorage(BodyWeightUnit.preferenceKey) private var unitRawValue = BodyWeightUnit.kilograms.rawValue

    @State private var enteredKg: Double
    @State private var errorMessage: String?

    private var unit: BodyWeightUnit {
        BodyWeightUnit(rawValue: unitRawValue) ?? .kilograms
    }

    init(userId: String, initialWeightKg: Double?, onWeighIn: @escaping (Double) -> Void) {
        self.userId = userId
        self.onWeighIn = onWeighIn

        let seed = (initialWeightKg ?? 75) > 0 ? (initialWeightKg ?? 75) : 75
        _enteredKg = State(initialValue: BodyWeight.clampedToRange(seed))
    }

    var body: some View {
        AdaptiveScrollContainer {
            VStack(spacing: 20) {
                header

                WeightUnitSegmentedControl(unitRawValue: $unitRawValue)

                summaryCard
                inputCard

                if let message = errorMessage ?? viewModel.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .navigationTitle("Weigh in")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                toolbarIconButton(systemImage: "xmark", action: { dismiss() })
            }
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    toolbarIconButton(systemImage: "checkmark", action: handleDone)
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isSaving)
    }

    // MARK: - UI

    private func toolbarIconButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .tint(.secondary)
    }

    private var header: some View {
        VStack(spacing: 14) {
            Image(systemName: "scalemass")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(Color.fuelOrange)
                .frame(width: 96, height: 96)
                .background(Color.fuelOrange.opacity(0.14), in: Circle())
                .shadow(color: Color.fuelOrange.opacity(0.12), radius: 18, y: 10)
                .padding(.top, 12)

            Text("Weigh in under the same conditions each time — first thing in the morning is easiest to repeat.")
                .font(.footnote)
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
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }

    /// Two adjacent wheels rather than one 0.1-step wheel: a single wheel over
    /// 30.0–200.0 kg is 1,701 rows, and scrolling 75 → 120 is unusable.
    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(unit == .kilograms ? "Weight (kg)" : "Weight (lbs)")
                .font(.headline)

            HStack(spacing: 0) {
                Picker("", selection: wholeBinding) {
                    ForEach(wholeRange, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
                .accessibilityLabel(unit == .kilograms ? "Kilograms" : "Pounds")

                Picker("", selection: tenthBinding) {
                    ForEach(tenthRange, id: \.self) { value in
                        Text(".\(value)").tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
                .accessibilityLabel("Decimal")
            }
            .frame(height: 160)
            .labelsHidden()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }

    // MARK: - Derived values

    /// The value shown on the wheels, in the selected unit.
    private var displayedValue: Double {
        unit == .kilograms ? enteredKg : BodyWeight.pounds(fromKilograms: enteredKg)
    }

    /// Both bounds derive from the kilogram range, so a value near either end no
    /// longer shifts when the unit is switched. The old `30...200` kg and
    /// `66...440` lb ranges were not mirrors of each other.
    private var wholeRange: [Int] {
        let lower: Double
        let upper: Double
        if unit == .kilograms {
            lower = BodyWeight.minimumKilograms
            upper = BodyWeight.maximumKilograms
        } else {
            lower = BodyWeight.pounds(fromKilograms: BodyWeight.minimumKilograms)
            upper = BodyWeight.pounds(fromKilograms: BodyWeight.maximumKilograms)
        }
        return Array(Int(lower.rounded(.up))...Int(upper.rounded(.down)))
    }

    /// Pounds step in 0.2 — a finer step would imply precision no bathroom scale
    /// offers, and 0.2 lb survives the kilogram round trip exactly.
    private var tenthRange: [Int] {
        unit == .kilograms ? Array(0...9) : [0, 2, 4, 6, 8]
    }

    private var wholeBinding: Binding<Int> {
        Binding(
            get: { BodyWeight.decompose(displayedValue).whole },
            set: { setDisplayed(whole: $0, tenth: BodyWeight.decompose(displayedValue).tenth) }
        )
    }

    private var tenthBinding: Binding<Int> {
        Binding(
            get: { BodyWeight.decompose(displayedValue).tenth },
            set: { setDisplayed(whole: BodyWeight.decompose(displayedValue).whole, tenth: $0) }
        )
    }

    /// The single write path into `enteredKg`. Both wheels funnel through here,
    /// so there is no feedback loop to drift.
    private func setDisplayed(whole: Int, tenth: Int) {
        let value = BodyWeight.recompose(whole: whole, tenth: tenth)
        let kg = unit == .kilograms ? value : BodyWeight.kilograms(fromPounds: value)
        enteredKg = BodyWeight.clampedToRange(BodyWeight.roundedForStorage(kg))
    }

    private var primaryWeightText: String {
        BodyWeight.displayString(kilograms: enteredKg, unit: unit)
    }

    private var secondaryWeightText: String {
        let other: BodyWeightUnit = unit == .kilograms ? .pounds : .kilograms
        return "≈ " + BodyWeight.displayString(kilograms: enteredKg, unit: other)
    }

    // MARK: - Done

    private func handleDone() {
        errorMessage = nil
        viewModel.clearError()

        guard enteredKg > 0 else {
            errorMessage = "Please select a valid weight."
            return
        }

        let kg = BodyWeight.roundedForStorage(enteredKg)

        Task {
            let saved = await viewModel.recordWeighIn(userId: userId, weightKg: kg)
            guard saved else { return }
            onWeighIn(kg)
            dismiss()
        }
    }
}

private struct WeightUnitSegmentedControl: View {
    @Binding var unitRawValue: String

    var body: some View {
        HStack(spacing: 0) {
            segment(unit: .kilograms)
            segment(unit: .pounds)
        }
        .padding(4)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func segment(unit: BodyWeightUnit) -> some View {
        let isSelected = unitRawValue == unit.rawValue

        return Button {
            unitRawValue = unit.rawValue
        } label: {
            Text(unit.shortLabel)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(isSelected ? Color(.systemBackground) : Color.clear)
                )
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    NavigationStack {
        EditWeightSheet(userId: "preview", initialWeightKg: 83.4, onWeighIn: { _ in })
    }
}
