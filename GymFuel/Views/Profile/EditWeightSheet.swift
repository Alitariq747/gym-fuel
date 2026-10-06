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
/// - **0.1 precision.** At whole-kilogram resolution the chart cannot show a
///   0.3 kg week, so the line would be noise rather than a direction.
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

    @ScaledMetric(relativeTo: .largeTitle) private var readingSize: CGFloat = 52

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
            VStack(alignment: .leading, spacing: 14) {
                header
                weightCard

                if let message = errorMessage ?? viewModel.errorMessage {
                    Text(message)
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaDanger)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: handleDone) {
                    Group {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(Color.circaPaperTop)
                        } else {
                            Text("Save")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary, height: 52))
                .disabled(viewModel.isSaving)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.vertical, 18)
        }
        .circaPaper()
        .interactiveDismissDisabled(viewModel.isSaving)
        // The two wheels step differently, so the same weight is not on a row in
        // both units. Snap, or the summary and the wheel disagree.
        .onChange(of: unitRawValue) { _, _ in enteredKg = WeightWheel(unit).snapped(enteredKg) }
    }

    // MARK: - UI

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weigh in")
                    .font(.circaTitle)
                    .foregroundStyle(Color.circaInk)
                Text("Weigh in under the same conditions each time — first thing in the morning is easiest to repeat.")
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Circa.Space.rowGap)
            Button("Cancel") { dismiss() }
                .buttonStyle(.circa(.quiet))
        }
    }

    /// A weigh-in is a measurement, so the reading carries no certainty rule.
    private var weightCard: some View {
        CircaCard {
            VStack(spacing: Circa.Space.rowGap) {
                HStack {
                    CircaSectionLabel("Weight")
                    Spacer(minLength: Circa.Space.rowGap)
                    UnitToggle(
                        options: BodyWeightUnit.allCases,
                        label: { $0.shortLabel },
                        selection: $unitRawValue.asBodyWeightUnit
                    )
                }

                VStack(spacing: 4) {
                    Text(primaryWeightText)
                        .font(.system(size: readingSize, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.circaAccentLarge)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(secondaryWeightText)
                        .font(.circaMono)
                        .foregroundStyle(Color.circaInk3)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)

                CircaHairline(weight: .inCard)

                wheels
            }
        }
    }

    /// Two adjacent wheels rather than one 0.1-step wheel: a single wheel over
    /// 30.0–200.0 kg is 1,701 rows, and scrolling 75 → 120 is unusable.
    private var wheels: some View {
        HStack(spacing: 0) {
            Picker("", selection: wholeBinding) {
                ForEach(wheel.wholeRange, id: \.self) { value in
                    Text("\(value)").font(.circaMonoValue).tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .clipped()
            .accessibilityLabel(unit == .kilograms ? "Kilograms" : "Pounds")

            Picker("", selection: tenthBinding) {
                ForEach(wheel.tenthRange, id: \.self) { value in
                    Text(".\(value)").font(.circaMonoValue).tag(value)
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
    EditWeightSheet(userId: "preview", initialWeightKg: 83.4, onWeighIn: { _ in })
}
