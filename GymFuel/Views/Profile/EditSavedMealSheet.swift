import SwiftUI

struct EditSavedMealSheet: View {
    let meal: SavedMeal

    @EnvironmentObject private var savedMealsViewModel: SavedMealsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var nameText: String
    @State private var descriptionText: String
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var carbsText: String
    @State private var fatText: String
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation: Bool = false

    init(meal: SavedMeal) {
        self.meal = meal
        _nameText = State(initialValue: meal.name)
        _descriptionText = State(initialValue: meal.description ?? "")
        _caloriesText = State(initialValue: Self.macroText(meal.macros.calories))
        _proteinText = State(initialValue: Self.macroText(meal.macros.protein))
        _carbsText = State(initialValue: Self.macroText(meal.macros.carbs))
        _fatText = State(initialValue: Self.macroText(meal.macros.fat))
        _errorMessage = State(initialValue: nil)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Edit saved meal")
                            .font(.title3.weight(.bold))
                        Text("Refine the reusable meal details and macro targets.")
                            .font(.footnote)
                            .foregroundStyle(Color.circaInk2)
                    }

                    VStack(spacing: 12) {
                        SavedMealTextField(systemImage: "fork.knife", title: "Meal name", text: $nameText, color: .circaInk)
                        SavedMealTextField(systemImage: "text.alignleft", title: "Description", text: $descriptionText, color: .circaInk2, lineLimit: 3...6)
                    }

                    SavedMealMacrosCard(calories: $caloriesText, protein: $proteinText, carbs: $carbsText, fat: $fatText)

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(Color.circaDanger)
                            .font(.footnote)
                    }

                    if let viewModelError = savedMealsViewModel.errorMessage {
                        Text(viewModelError)
                            .foregroundStyle(Color.circaDanger)
                            .font(.footnote)
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                            Text("Delete Meal")
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(20)
                .onChange(of: nameText) { _, _ in clearErrors() }
                .onChange(of: descriptionText) { _, _ in clearErrors() }
                .onChange(of: caloriesText) { _, _ in clearErrors() }
                .onChange(of: proteinText) { _, _ in clearErrors() }
                .onChange(of: carbsText) { _, _ in clearErrors() }
                .onChange(of: fatText) { _, _ in clearErrors() }
            }
            .background(LinearGradient.circaPaper.ignoresSafeArea())
            .navigationTitle("Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CircaCloseButton { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    CircaConfirmButton(isEnabled: canSave, isWorking: savedMealsViewModel.isLoading) { saveEditedMeal() }
                }
            }
        }
        .presentationDetents([.large])
        .confirmationDialog(
            "Delete this meal from saved meals? This action can not be reversed",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    let didDelete = await savedMealsViewModel.deleteSavedMeal(meal)
                    if didDelete {
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func clearErrors() {
        errorMessage = nil
        savedMealsViewModel.clearErrorMessage()
    }

    private var editedMacros: Macros {
        Macros(
            calories: Double(caloriesText) ?? 0,
            protein: Double(proteinText) ?? 0,
            carbs: Double(carbsText) ?? 0,
            fat: Double(fatText) ?? 0
        )
    }

    private var canSave: Bool {
        let hasName = !nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let macros = editedMacros
        return hasName && (macros.calories > 0 || macros.protein > 0 || macros.carbs > 0 || macros.fat > 0)
    }

    private func saveEditedMeal() {
        let trimmedName = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            errorMessage = "Please add a name."
            return
        }

        let calories = Double(caloriesText) ?? 0
        let protein = Double(proteinText) ?? 0
        let carbs = Double(carbsText) ?? 0
        let fat = Double(fatText) ?? 0

        if calories == 0 && protein == 0 && carbs == 0 && fat == 0 {
            errorMessage = "Please add at least one macro value."
            return
        }

        errorMessage = nil

        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDescription = trimmedDescription.isEmpty ? nil : trimmedDescription

        let typed = Macros(calories: calories, protein: protein, carbs: carbs, fat: fat)

        // Built from the existing meal, so renaming it keeps the breakdown it was
        // saved for. Retyping the totals is the override, and only that.
        var updatedMeal = meal
        updatedMeal.name = trimmedName
        updatedMeal.description = finalDescription
        updatedMeal.macros = typed

        if typed.rounded() != meal.macros.rounded() {
            updatedMeal = MealBreakdownCalculator.superseding(updatedMeal, withUserTotal: typed)
        }

        Task {
            let didUpdate = await savedMealsViewModel.updateSavedMeal(updatedMeal)
            if didUpdate {
                dismiss()
            }
        }
    }

    private static func macroText(_ value: Double) -> String {
        guard value != 0 else { return "" }
        let intValue = Int(value)
        if Double(intValue) == value {
            return String(intValue)
        }
        return String(value)
    }
}

#Preview {
    EditSavedMealSheet(
        meal: SavedMeal(
            id: UUID().uuidString,
            userId: "preview-user",
            name: "Chicken rice bowl",
            description: "Chicken, rice, avocado, and salsa",
            macros: Macros(calories: 620, protein: 45, carbs: 70, fat: 18)
        )
    )
    .environmentObject(SavedMealsViewModel())
}
