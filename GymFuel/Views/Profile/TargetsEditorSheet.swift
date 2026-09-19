//
//  TargetsEditorSheet.swift
//  GymFuel
//

import SwiftUI

/// Editing the four daily numbers. Calories, protein and fat are typed; carbs take
/// what is left, and the calorie floors hold — `MacroTargetCalculator.edited` owns
/// both of those rules, not this view.
///
/// It knows nothing about profiles or Firebase: it is handed a starting point and
/// hands back a result, so the plan screen (4f) can use it before an account has
/// anything saved.
struct TargetsEditorSheet: View {
    let gender: Gender
    let onSave: (Macros) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var fatText: String
    @FocusState private var focusedField: Field?
    @ScaledMetric(relativeTo: .title3) private var fieldWidth: CGFloat = 108

    private enum Field {
        case calories, protein, fat
    }

    init(targets: Macros, gender: Gender, onSave: @escaping (Macros) -> Void) {
        self.gender = gender
        self.onSave = onSave
        _caloriesText = State(initialValue: Self.digits(targets.calories))
        _proteinText = State(initialValue: Self.digits(targets.protein))
        _fatText = State(initialValue: Self.digits(targets.fat))
    }

    /// What Save will write: the typed numbers with carbs filled and the floors
    /// applied. Nil while any field is empty or not a number, which disables Save.
    private var resolved: Macros? {
        guard let calories = Double(caloriesText),
              let protein = Double(proteinText),
              let fat = Double(fatText) else { return nil }

        return MacroTargetCalculator.edited(
            calories: calories,
            proteinG: protein,
            fatG: fat,
            gender: gender
        )
    }

    var body: some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 14) {
                header

                CircaCard {
                    VStack(alignment: .leading, spacing: Circa.Space.rowGap) {
                        field("Calories", unit: "kcal", text: $caloriesText, focus: .calories)
                        CircaHairline(weight: .inCard)
                        field("Protein", unit: "g", text: $proteinText, focus: .protein)
                        CircaHairline(weight: .inCard)
                        field("Fat", unit: "g", text: $fatText, focus: .fat)
                        CircaHairline(weight: .inCard)
                        carbsRow
                    }
                }

                if let floorNote {
                    Text(floorNote)
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button(action: save) {
                    Text("Save").frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary, height: 52))
                .disabled(resolved == nil)
            }
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.vertical, 18)
        }
        .circaPaper()
    }

    // MARK: - Parts

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Edit your targets")
                .font(.circaTitle)
                .foregroundStyle(Color.circaInk)
            Spacer(minLength: Circa.Space.rowGap)
            Button("Cancel") { dismiss() }
                .buttonStyle(.circa(.quiet))
        }
    }

    /// Label above the field rather than beside it, so nothing has to truncate at
    /// accessibility sizes — `design.md` rule 8, solved by the layout instead of a
    /// branch.
    private func field(_ title: String, unit: String, text: Binding<String>, focus: Field) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            CircaSectionLabel(title)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("0", text: text)
                    .font(.circaMonoLarge)
                    .monospacedDigit()
                    .foregroundStyle(Color.circaInk)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: focus)
                    .frame(width: fieldWidth)
                Text(unit)
                    .font(.circaMono)
                    .foregroundStyle(Color.circaInk3)
                Spacer(minLength: 0)
            }
        }
        .frame(minHeight: Circa.minHitTarget, alignment: .leading)
    }

    /// Carbs are shown, never typed: they are whatever the other three leave.
    private var carbsRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            CircaSectionLabel("Carbs")

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(resolved.map { Self.digits($0.carbs) } ?? "—")
                    .font(.circaMonoLarge)
                    .monospacedDigit()
                    .foregroundStyle(Color.circaInk2)
                    .frame(width: fieldWidth, alignment: .leading)
                Text("g · what the others leave")
                    .font(.circaMono)
                    .foregroundStyle(Color.circaInk3)
                Spacer(minLength: 0)
            }
        }
    }

    /// Why the calories about to be saved are higher than the ones typed. Which
    /// floor bit is worth saying: "the lowest this app sets" and "your protein and
    /// fat" are different things to change.
    private var floorNote: String? {
        guard let resolved,
              let typed = Double(caloriesText),
              resolved.calories > typed.rounded() else { return nil }

        let held = Self.grouped(resolved.calories)
        return resolved.calories <= SafetyLimits.calorieFloor(for: gender)
            ? "Saving as \(held) kcal — the lowest this app will set."
            : "Saving as \(held) kcal — less would not cover the protein and fat above."
    }

    // MARK: - Actions and numbers

    private func save() {
        guard let resolved else { return }
        focusedField = nil
        onSave(resolved)
        dismiss()
    }

    /// Plain digits, for a field that is typed into.
    private static func digits(_ value: Double) -> String {
        String(Int(value.rounded()))
    }

    /// Grouped thousands, for prose.
    private static func grouped(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }
}

#if DEBUG
#Preview("Edit targets") {
    TargetsEditorSheet(
        targets: Macros(calories: 1_950, protein: 125, carbs: 195, fat: 62),
        gender: .female,
        onSave: { _ in }
    )
}
#endif
