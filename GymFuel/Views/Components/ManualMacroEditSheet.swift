import SwiftUI

struct ManualMacroEditSheet: View {
    private enum Mode {
        case food(Macros)
        case exercise(Double)
    }

    private let mode: Mode
    var onSaveMacros: ((Macros) -> Void)? = nil
    var onSaveCaloriesBurned: ((Double) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var carbsText: String
    @State private var fatText: String
    @FocusState private var isInputFocused: Bool

    init(initialMacros: Macros, onSave: ((Macros) -> Void)? = nil) {
        self.mode = .food(initialMacros)
        self.onSaveMacros = onSave
        _caloriesText = State(initialValue: Self.string(initialMacros.calories))
        _proteinText = State(initialValue: Self.string(initialMacros.protein))
        _carbsText = State(initialValue: Self.string(initialMacros.carbs))
        _fatText = State(initialValue: Self.string(initialMacros.fat))
    }

    init(initialCaloriesBurned: Double, onSave: ((Double) -> Void)? = nil) {
        self.mode = .exercise(initialCaloriesBurned)
        self.onSaveCaloriesBurned = onSave
        _caloriesText = State(initialValue: Self.string(initialCaloriesBurned))
        _proteinText = State(initialValue: "")
        _carbsText = State(initialValue: "")
        _fatText = State(initialValue: "")
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text(isExerciseEditor ? "Edit Calories Burned" : "Edit Macros")
                    .font(.title3.weight(.bold))
                Text(editorSubtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if isExerciseEditor {
                    macroBox("Calories Burned", suffix: "kcal", text: $caloriesText)
                } else {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        macroBox("Calories", suffix: "kcal", text: $caloriesText)
                        macroBox("Protein", suffix: "g", text: $proteinText)
                        macroBox("Carbs", suffix: "g", text: $carbsText)
                        macroBox("Fat", suffix: "g", text: $fatText)
                    }
                }
                Spacer(minLength: 0)
                Button {
                    isInputFocused = false
                    if let updatedMacros {
                        onSaveMacros?(updatedMacros)
                    } else if let updatedCaloriesBurned {
                        onSaveCaloriesBurned?(updatedCaloriesBurned)
                    } else {
                        return
                    }

                    dismiss()
                } label: {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                }
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.liftEatsCoral, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .disabled(updatedMacros == nil && updatedCaloriesBurned == nil)
            }
            .padding()
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium])
    }

    private var isExerciseEditor: Bool {
        if case .exercise = mode { return true }
        return false
    }

    private var editorSubtitle: String {
        isExerciseEditor ?
            "Adjust the calorie burn estimate manually." :
            "Adjust the nutrition values manually."
    }

    private var updatedMacros: Macros? {
        guard !isExerciseEditor else { return nil }
        guard let calories = Double(caloriesText),
              let protein = Double(proteinText),
              let carbs = Double(carbsText),
              let fat = Double(fatText) else { return nil }
        return Macros(calories: calories, protein: protein, carbs: carbs, fat: fat)
    }

    private var updatedCaloriesBurned: Double? {
        guard isExerciseEditor else { return nil }
        return Double(caloriesText)
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
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                TextField("0", text: text)
                    .font(.title3.weight(.bold))
                    .keyboardType(.decimalPad)
                    .focused($isInputFocused)
                Text(suffix)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.quaternaryLabel).opacity(0.65), lineWidth: 1)
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
