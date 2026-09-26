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
        // Snapped to a row the wheel actually offers. The last weigh-in may have
        // been in the other unit, or come from Apple Health at full precision.
        // `@AppStorage` is not readable yet here, so the preference is read direct.
        let stored = UserDefaults.standard.string(forKey: BodyWeightUnit.preferenceKey)
        let unit = BodyWeightUnit(rawValue: stored ?? "") ?? .kilograms
        _enteredKg = State(initialValue: WeightWheel(unit).snapped(seed))
    }

    var body: some View {
        AdaptiveScrollContainer {
            VStack(spacing: 20) {
                header

                UnitToggle(
                    options: BodyWeightUnit.allCases,
                    label: { $0.shortLabel },
                    selection: $unitRawValue.asBodyWeightUnit
                )

                summaryCard
                inputCard

                if let message = errorMessage ?? viewModel.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Color.circaDanger)
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
        // The two wheels step differently, so the same weight is not on a row in
        // both units. Snap, or the summary and the wheel disagree.
        .onChange(of: unitRawValue) { _, _ in enteredKg = WeightWheel(unit).snapped(enteredKg) }
    }

    // MARK: - UI

    private func toolbarIconButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.circaInk2)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .tint(Color.circaInk2)
    }

    private var header: some View {
        VStack(spacing: 14) {
            Image(systemName: "scalemass")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(Color.circaAccent)
                .frame(width: 96, height: 96)
                .background(Color.circaWell, in: Circle())
                .padding(.top, 12)

            Text("Weigh in under the same conditions each time — first thing in the morning is easiest to repeat.")
                .font(.footnote)
                .foregroundStyle(Color.circaInk2)
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
                .foregroundStyle(Color.circaInk2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.circaCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.circaCardBorder, lineWidth: 1)
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
                    ForEach(wheel.wholeRange, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
                .accessibilityLabel(unit == .kilograms ? "Kilograms" : "Pounds")

                Picker("", selection: tenthBinding) {
                    ForEach(wheel.tenthRange, id: \.self) { value in
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
                .fill(Color.circaCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.circaCardBorder, lineWidth: 1)
        )
    }

    // MARK: - Derived values

    private var wheel: WeightWheel { WeightWheel(unit) }

    private var wholeBinding: Binding<Int> {
        Binding(
            get: { wheel.digits(enteredKg).whole },
            set: { enteredKg = wheel.kilograms(whole: $0, tenth: wheel.digits(enteredKg).tenth) }
        )
    }

    private var tenthBinding: Binding<Int> {
        Binding(
            get: { wheel.digits(enteredKg).tenth },
            set: { enteredKg = wheel.kilograms(whole: wheel.digits(enteredKg).whole, tenth: $0) }
        )
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

#Preview {
    NavigationStack {
        EditWeightSheet(userId: "preview", initialWeightKg: 83.4, onWeighIn: { _ in })
    }
}
