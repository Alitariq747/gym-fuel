//
//  SavedMealFields.swift
//  GymFuel
//

import SwiftUI

/// The fields the three saved-meal sheets share: add, edit, and save from the log.

/// A name or description, with its symbol in a well.
struct SavedMealTextField: View {
    let systemImage: String
    let title: String
    @Binding var text: String
    let color: Color
    var lineLimit: ClosedRange<Int>?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(Color.circaWell, in: Circle())
            Group {
                if let lineLimit {
                    TextField(title, text: $text, axis: .vertical)
                        .lineLimit(lineLimit)
                } else {
                    TextField(title, text: $text, axis: .vertical)
                }
            }
            .font(.subheadline.weight(.medium))
        }
        .padding(14)
        .background(Color.circaCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// The four macros, each typed as text.
struct SavedMealMacrosCard: View {
    @Binding var calories: String
    @Binding var protein: String
    @Binding var carbs: String
    @Binding var fat: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Macros", systemImage: "chart.bar.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.circaInk2)
            MacroField(title: "Calories", glyph: .calories, text: $calories)
            MacroField(title: "Protein", glyph: .protein, text: $protein)
            MacroField(title: "Carbs", glyph: .carbs, text: $carbs)
            MacroField(title: "Fat", glyph: .fat, text: $fat)
        }
        .padding(16)
        .background(Color.circaCard, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct MacroField: View {
    let title: String
    let glyph: CircaMacroGlyph.Macro
    @Binding var text: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(spacing: 12))

        layout {
            CircaMacroGlyph(glyph)
            Text(title)
                .font(.subheadline.weight(.semibold))
            if !dynamicTypeSize.isAccessibilitySize { Spacer() }
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.subheadline.weight(.bold))
                .frame(minWidth: 74, alignment: .trailing)
        }
        .padding(12)
        .background(Color.circaSunken, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
