import SwiftUI

struct ManualMacroEditSheet: View {
    var onSaveMacros: ((Macros) -> Void)? = nil
    /// Whether saving here will discard an item breakdown — `meal-contract.md` §6.
    var supersedesBreakdown: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var carbsText: String
    @State private var fatText: String
    @FocusState private var isInputFocused: Bool

    init(
        initialMacros: Macros,
        supersedesBreakdown: Bool = false,
        onSave: ((Macros) -> Void)? = nil
    ) {
        self.onSaveMacros = onSave
        self.supersedesBreakdown = supersedesBreakdown
        _caloriesText = State(initialValue: Self.string(initialMacros.calories))
        _proteinText = State(initialValue: Self.string(initialMacros.protein))
        _carbsText = State(initialValue: Self.string(initialMacros.carbs))
        _fatText = State(initialValue: Self.string(initialMacros.fat))
    }

    var body: some View {
        NavigationStack {
            AdaptiveScrollContainer {
                VStack(alignment: .leading, spacing: 18) {
                Text("Edit Macros")
                    .font(.circaTitle)
                    .foregroundStyle(Color.circaInk)
                Text(editorSubtitle)
                    .font(.footnote)
                    .foregroundStyle(Color.circaInk2)
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    macroBox("Calories", suffix: "kcal", text: $caloriesText)
                    macroBox("Protein", suffix: "g", text: $proteinText)
                    macroBox("Carbs", suffix: "g", text: $carbsText)
                    macroBox("Fat", suffix: "g", text: $fatText)
                }
                Spacer(minLength: 0)
                if supersedesBreakdown {
                    // Said here, beside Save, rather than in a dialog afterwards:
                    // the user should know what a typed total costs while they are
                    // deciding what to type.
                    Text("Saving a total you type will remove the item breakdown and its assumptions — they describe a different meal. The total stays.")
                        .font(.footnote)
                        .foregroundStyle(Color.circaAccent)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button {
                    isInputFocused = false
                    guard let updatedMacros else { return }
                    onSaveMacros?(updatedMacros)

                    dismiss()
                } label: {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                }
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.circaPaperTop)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.circaInk, in: RoundedRectangle(cornerRadius: Circa.Radius.button, style: .continuous))
                .disabled(updatedMacros == nil)
            }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(LinearGradient.circaPaper)
        .presentationContentInteraction(.scrolls)
    }

    private var editorSubtitle: String {
        "Adjust the nutrition values manually."
    }

    private var updatedMacros: Macros? {
        guard let calories = Double(caloriesText),
              let protein = Double(proteinText),
              let carbs = Double(carbsText),
              let fat = Double(fatText) else { return nil }
        return Macros(calories: calories, protein: protein, carbs: carbs, fat: fat)
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ]
    }

    private func macroBox(
        _ title: String,
        suffix: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.circaInk2)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0", text: text)
                    .font(.title3.weight(.bold))
                    .keyboardType(.decimalPad)
                    .focused($isInputFocused)
                Text(suffix)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.circaInk3)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .background(Color.circaCard, in: RoundedRectangle(cornerRadius: Circa.Radius.cardSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Circa.Radius.cardSmall, style: .continuous)
                .stroke(Color.circaCardBorder, lineWidth: 1)
        )
    }

    private static func string(_ value: Double) -> String {
        String(Int(value.rounded()))
    }
}

#Preview {
    ManualMacroEditSheet(
        initialMacros: Macros(calories: 620, protein: 44, carbs: 52, fat: 20)
    )
}
