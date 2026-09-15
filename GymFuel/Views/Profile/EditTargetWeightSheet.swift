//
//  EditTargetWeightSheet.swift
//  GymFuel
//

import SwiftUI

/// Sets or clears the optional target weight on the Settings draft.
///
/// Writes nothing itself — it edits the draft, and Settings' Save persists it.
/// The wheels only offer values `TargetWeight.allowedRange` accepts, so an
/// underweight or wrong-side target cannot be picked at all. No finish date is
/// ever shown (`build-order.md` decision 10).
///
/// Legacy Profile styling, like the other Settings pickers — Step 7a rebuilds
/// the screen in one pass.
struct EditTargetWeightSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(BodyWeightUnit.preferenceKey) private var unitRawValue = BodyWeightUnit.kilograms.rawValue

    @Binding var targetWeightKg: Double?
    let goal: GoalType
    private let range: ClosedRange<Double>?

    @State private var enteredKg: Double

    init(targetWeightKg: Binding<Double?>, goal: GoalType, currentWeightKg: Double?, heightCm: Double?) {
        _targetWeightKg = targetWeightKg
        self.goal = goal

        let range = TargetWeight.allowedRange(goal: goal, currentWeightKg: currentWeightKg, heightCm: heightCm)
        self.range = range

        // Start on the saved target, or on the allowed value nearest today's weight.
        let seed: Double
        if let saved = targetWeightKg.wrappedValue, let range, range.contains(saved) {
            seed = saved
        } else if let range {
            seed = goal == .cut ? range.upperBound : range.lowerBound
        } else {
            seed = currentWeightKg ?? 75
        }
        _enteredKg = State(initialValue: seed)
    }

    private var unit: BodyWeightUnit {
        BodyWeightUnit(rawValue: unitRawValue) ?? .kilograms
    }

    var body: some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 16) {
                header

                if range != nil {
                    Text(BodyWeight.displayString(kilograms: enteredKg, unit: unit))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity)

                    wheels
                    setButton
                } else {
                    Text(unavailableText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if targetWeightKg != nil {
                    clearButton
                }

                Text("Optional. It is compared with your weight trend, not a single weigh-in, and we never put a date on reaching it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - UI

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Target weight")
                    .font(.headline.weight(.bold))
                Text(goal == .cut ? "Below your current weight." : "Above your current weight.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var unavailableText: String {
        goal == .cut
            ? "A lower target isn't available: at your height, anything below your current weight would be in the underweight range."
            : "A target weight isn't available right now."
    }

    /// Two wheels, whole units and tenths, as in `EditWeightSheet`.
    private var wheels: some View {
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
        .padding(12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var setButton: some View {
        Button {
            targetWeightKg = enteredKg
            dismiss()
        } label: {
            Text("Set target")
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    colorScheme == .dark ? Color(.secondarySystemBackground) : Color.black,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }

    private var clearButton: some View {
        Button {
            targetWeightKg = nil
            dismiss()
        } label: {
            Text("Clear target")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Wheels

    private var displayedValue: Double {
        unit == .kilograms ? enteredKg : BodyWeight.pounds(fromKilograms: enteredKg)
    }

    /// Floor to floor, not ceil to floor: a range narrower than one whole unit
    /// would otherwise produce an empty — crashing — `lower...upper`.
    private var wholeRange: [Int] {
        guard let range else { return [] }
        let lower = unit == .kilograms ? range.lowerBound : BodyWeight.pounds(fromKilograms: range.lowerBound)
        let upper = unit == .kilograms ? range.upperBound : BodyWeight.pounds(fromKilograms: range.upperBound)
        return Array(Int(lower.rounded(.down))...Int(upper.rounded(.down)))
    }

    /// Pounds step in 0.2, matching `EditWeightSheet`.
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

    /// The single write path into `enteredKg`, clamped to the allowed range.
    private func setDisplayed(whole: Int, tenth: Int) {
        guard let range else { return }
        let value = BodyWeight.recompose(whole: whole, tenth: tenth)
        let kg = unit == .kilograms ? value : BodyWeight.kilograms(fromPounds: value)
        let rounded = BodyWeight.roundedForStorage(kg)
        enteredKg = min(max(rounded, range.lowerBound), range.upperBound)
    }
}
