//
//  TargetsEditorSheet.swift
//  GymFuel
//

import SwiftUI

/// Editing the four daily numbers.
///
/// It asks before it moves anything: a typed number stands, the other three stay
/// exactly where they were, and a prompt offers the ways to reconcile them.
/// `TargetReconciler` owns every one of those answers and the calorie floors —
/// this view only draws them and hands back the one the user picked.
///
/// It knows nothing about profiles or Firebase: it is handed a starting point and
/// hands back a result, so the plan screen (4f) can use it before an account has
/// anything saved.
struct TargetsEditorSheet: View {
    let targets: Macros
    let gender: Gender
    /// The weight protein and fat are worked out from, and the goal that sets
    /// their grams per kg. Both exist only for *Recalculate macros*, which comes
    /// from the rules rather than from what is on screen.
    let basisKg: Double
    let goal: GoalType
    let onSave: (Macros) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    /// What the fields were last seeded from: the saved targets, then the result
    /// of each resolution. Moving it with the fields is what stops a resolution
    /// the user just accepted from reading back as a fresh edit.
    @State private var baseline: Macros
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var carbsText: String
    @State private var fatText: String
    /// Only a "not dismissed" flag. What decides whether the summary is *shown*
    /// is whether there is an unresolved edit, which the prompt owns.
    @State private var isConfirming = false
    /// The calories the last resolution was asked for, so a floor lift can say so.
    @State private var requestedCalories: Double?
    @FocusState private var focusedField: TargetField?
    @ScaledMetric(relativeTo: .title3) private var fieldWidth: CGFloat = 108

    /// Which question the prompt is asking. Calories win when both were edited,
    /// because *Recalculate macros* replaces all three macros anyway.
    private enum Prompt: Equatable {
        case calories, macros
    }

    private enum Resolution: Equatable {
        case recalculateMacros, recalculateCalories, adjustMacros
    }

    init(
        targets: Macros,
        gender: Gender,
        basisKg: Double,
        goal: GoalType,
        onSave: @escaping (Macros) -> Void
    ) {
        self.targets = targets
        self.gender = gender
        self.basisKg = basisKg
        self.goal = goal
        self.onSave = onSave
        _baseline = State(initialValue: targets)
        _caloriesText = State(initialValue: Self.digits(targets.calories))
        _proteinText = State(initialValue: Self.digits(targets.protein))
        _carbsText = State(initialValue: Self.digits(targets.carbs))
        _fatText = State(initialValue: Self.digits(targets.fat))
    }

    // MARK: - What the fields say

    /// The four fields as numbers. Nil while any is empty or not a number.
    private var typed: Macros? {
        guard let calories = Double(caloriesText),
              let protein = Double(proteinText),
              let carbs = Double(carbsText),
              let fat = Double(fatText) else { return nil }

        return Macros(calories: calories, protein: protein, carbs: carbs, fat: fat)
    }

    private var changed: Set<TargetField> {
        guard let typed else { return [] }
        return TargetReconciler.changedFields(in: typed, from: baseline)
    }

    private var prompt: Prompt? {
        let fields = changed
        guard !fields.isEmpty else { return nil }
        return fields.contains(.calories) ? .calories : .macros
    }

    /// Nil when no macro is free to absorb, or when the typed macros already cost
    /// more than the calories. The reconciler decides that, not this view.
    private var adjusted: Macros? {
        guard let typed, prompt == .macros else { return nil }
        return TargetReconciler.adjustingMacros(typed, touched: changed, gender: gender)
    }

    private var canSave: Bool { typed != nil && changed.isEmpty }

    private var summaryLines: [TargetChange] {
        TargetReconciler.changes(from: targets, to: baseline)
    }

    private var summaryFloorNote: String? {
        guard let requestedCalories else { return nil }
        return TargetsCopy.floorNote(
            resolved: baseline,
            requestedCalories: requestedCalories,
            gender: gender
        )
    }

    var body: some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 14) {
                header

                CircaCard {
                    VStack(alignment: .leading, spacing: Circa.Space.rowGap) {
                        field(.calories, text: $caloriesText)
                        CircaHairline(weight: .inCard)
                        field(.protein, text: $proteinText)
                        CircaHairline(weight: .inCard)
                        field(.carbs, text: $carbsText)
                        CircaHairline(weight: .inCard)
                        field(.fat, text: $fatText)
                    }
                }

                if let prompt {
                    promptCard(prompt)
                } else if isConfirming, !summaryLines.isEmpty {
                    TargetsChangeSummary(
                        changes: summaryLines,
                        floorNote: summaryFloorNote
                    ) { isConfirming = false }
                }

                Spacer(minLength: 0)

                Button(action: save) {
                    Text("Save").frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary, height: 52))
                .disabled(!canSave)
                // `CircaButtonStyle` never reads `\.isEnabled`, so a disabled
                // primary would otherwise look exactly like a live one.
                .opacity(canSave ? 1 : 0.6)

                if let saveNote {
                    Text(saveNote)
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }
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
    private func field(_ field: TargetField, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            CircaSectionLabel(TargetsCopy.fieldLabel(field))

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("0", text: text)
                    .font(.circaMonoLarge)
                    .monospacedDigit()
                    .foregroundStyle(Color.circaInk)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: field)
                    .frame(width: fieldWidth)
                Text(TargetsCopy.fieldUnit(field))
                    .font(.circaMono)
                    .foregroundStyle(Color.circaInk3)
                Spacer(minLength: 0)
            }
        }
        .frame(minHeight: Circa.minHitTarget, alignment: .leading)
    }

    /// The house shape for an inline notice: a small sunken card, the sentence,
    /// and the ways out.
    private func promptCard(_ prompt: Prompt) -> some View {
        CircaCard(.sunken, radius: Circa.Radius.cardSmall) {
            VStack(alignment: .leading, spacing: 8) {
                Text(TargetsCopy.changedHeadline(changed))
                    .font(.circaEntryTitle)
                    .foregroundStyle(Color.circaInk)
                    .fixedSize(horizontal: false, vertical: true)

                if prompt == .macros {
                    Text(TargetsCopy.reconcileQuestion)
                        .font(.circaBody)
                        .foregroundStyle(Color.circaInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                actions(for: prompt)
            }
        }
    }

    /// Two peers rather than a primary and a fallback: the user is choosing which
    /// number holds, not accepting a suggestion. `.primary` is spoken for by Save.
    @ViewBuilder
    private func actions(for prompt: Prompt) -> some View {
        let buttons = Group {
            switch prompt {
            case .calories:
                Button("Recalculate macros") { apply(.recalculateMacros) }
                    .buttonStyle(.circa(.secondary))
            case .macros:
                Button("Recalculate calories") { apply(.recalculateCalories) }
                    .buttonStyle(.circa(.secondary))
                // Absent rather than disabled: with every macro typed there is no
                // answer that holds the calories, not a blocked one.
                if adjusted != nil {
                    Button("Adjust macros") { apply(.adjustMacros) }
                        .buttonStyle(.circa(.secondary))
                }
            }
        }

        // At accessibility sizes the pair stacks rather than shrinking — the 44pt
        // floor is not negotiable (`design.md` rule 8).
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) { buttons }
        } else {
            HStack(spacing: 8) {
                buttons
                Spacer(minLength: 0)
            }
        }
    }

    /// Why Save is unavailable. It sits under the button, and the prompt sits
    /// directly above it, so the reason and the remedy are adjacent.
    private var saveNote: String? {
        guard typed != nil else { return TargetsCopy.saveNeedsValue }
        return changed.isEmpty ? nil : TargetsCopy.savePickFirst
    }

    // MARK: - Actions and numbers

    /// Re-seeds all four fields from the answer and moves `baseline` with them.
    private func apply(_ resolution: Resolution) {
        guard let typed, let result = resolved(typed, by: resolution) else { return }

        baseline = result
        caloriesText = Self.digits(result.calories)
        proteinText = Self.digits(result.protein)
        carbsText = Self.digits(result.carbs)
        fatText = Self.digits(result.fat)
        // Recalculating the calories asks for what the macros cost; the other two
        // ask for the number already in the calorie field.
        requestedCalories = resolution == .recalculateCalories
            ? TargetReconciler.calorieCost(of: typed)
            : typed.calories
        isConfirming = true
        focusedField = nil
    }

    private func resolved(_ typed: Macros, by resolution: Resolution) -> Macros? {
        switch resolution {
        case .recalculateMacros:
            return TargetReconciler.recalculatingMacros(
                calories: typed.calories,
                basisKg: basisKg,
                goal: goal,
                gender: gender
            )
        case .recalculateCalories:
            return TargetReconciler.recalculatingCalories(typed, gender: gender)
        case .adjustMacros:
            return adjusted
        }
    }

    /// Saves `baseline` rather than the text: it is what a resolution produced,
    /// already floored and consistent, and Save is only reachable when the two
    /// agree anyway.
    private func save() {
        guard canSave else { return }
        focusedField = nil
        onSave(baseline)
        dismiss()
    }

    /// Plain digits, for a field that is typed into.
    private static func digits(_ value: Double) -> String {
        String(Int(value.rounded()))
    }
}

#if DEBUG
#Preview("Edit targets") {
    TargetsEditorSheet(
        targets: Macros(calories: 1_950, protein: 150, carbs: 203, fat: 60),
        gender: .male,
        basisKg: 75,
        goal: .cut,
        onSave: { _ in }
    )
}
#endif
