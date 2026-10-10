//
//  MealAmountsTotalBar.swift
//  GymFuel
//

import SwiftUI

/// The meal's total, what the edit does to it, and Save. It belongs in the
/// sheet's bottom safe-area inset, which is what keeps it on top of the keyboard.
struct MealAmountsTotalBar: View {
    let before: Int
    /// `nil` while a field is empty or unreadable.
    let after: Int?
    let certainty: CircaCertainty
    let changedCount: Int
    let canSave: Bool
    let isTyping: Bool
    let onHideKeyboard: () -> Void
    let onSave: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    /// design.md rule 8: the total goes above a full-width Save.
    private var isStacked: Bool { typeSize.isAccessibilitySize }

    var body: some View {
        let layout = isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(spacing: 6))

        layout {
            summary
            if !isStacked { Spacer(minLength: 8) }
            HStack(spacing: 6) {
                if isTyping { hideKeyboard }
                save
            }
        }
        .padding(.leading, Circa.Space.screenMargin)
        .padding(.trailing, Circa.Space.screenMarginWide)
        .padding(.vertical, 10)
        .background(Color.circaPaperBottom)
        .overlay(alignment: .top) { CircaHairline() }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                if let after, after != before {
                    Text("\(before.formatted()) →")
                        .font(.circaMonoValue)
                        .fontWeight(.regular)
                        .foregroundStyle(Color.circaInk3)
                }
                CircaEstimate((after ?? before).formatted(), certainty: certainty)
                    .foregroundStyle(Color.circaInk)
                Text("kcal")
                    .font(.circaMono)
                    .foregroundStyle(Color.circaInk3)
            }

            detail
                .font(.circaMono)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    @ViewBuilder
    private var detail: some View {
        if after == nil {
            Text(MealCopy.amountMissing)
                .foregroundStyle(Color.circaDanger)
        } else if changedCount == 0 {
            Text(MealCopy.nothingChanged)
                .foregroundStyle(Color.circaInk3)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                if let change = MealCopy.signedCalories((after ?? before) - before) {
                    Text(change)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.circaInk)
                    Text(verbatim: "·")
                        .foregroundStyle(Color.circaInk3)
                }
                Text(MealCopy.amountsChanged(changedCount))
                    .foregroundStyle(Color.circaInk3)
            }
        }
    }

    private var accessibilitySummary: String {
        guard let after else { return "Meal total \(before) kcal. \(MealCopy.amountMissing)" }
        guard changedCount > 0 else { return "Meal total \(before) kcal. \(MealCopy.nothingChanged)" }
        return "Meal total \(after) kcal, was \(before). \(MealCopy.amountsChanged(changedCount))"
    }

    private var hideKeyboard: some View {
        Button(action: onHideKeyboard) {
            Image(systemName: "keyboard.chevron.compact.down")
                .font(.body.weight(.medium))
                .foregroundStyle(Color.circaInk)
                .frame(minWidth: Circa.minHitTarget, minHeight: Circa.minHitTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Hide keyboard")
    }

    private var save: some View {
        Button(action: onSave) {
            Text("Save")
                .frame(maxWidth: isStacked ? .infinity : nil)
        }
        .buttonStyle(.circa(.primary))
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.45)
    }
}
