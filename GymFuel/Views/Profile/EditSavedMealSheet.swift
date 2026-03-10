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
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerRow

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nick name")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.secondary)

                        TextField("e.g Post workout shake", text: $nameText)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                            .background(
                                Color(.systemBackground),
                                in: RoundedRectangle(cornerRadius: 20)
                            )
                            .shadow(color: Color.black.opacity(0.12),
                                    radius: 6, x: 0, y: 3)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.secondary)

                        TextEditor(text: $descriptionText)
                            .font(.system(size: 18, weight: .regular))
                            .frame(minHeight: 80)
                            .foregroundStyle(.primary)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 14)
                            .background(
                                Color(.systemBackground),
                                in: RoundedRectangle(cornerRadius: 20)
                            )
                            .shadow(color: Color.black.opacity(0.12),
                                    radius: 6, x: 0, y: 3)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nutrition")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.secondary)

                        MacroRow(
                            title: "Calories",
                            systemImage: "flame.fill",
                            value: $caloriesText,
                            color: Color.fuelOrange
                        )
                        MacroRow(
                            title: "Protein",
                            systemImage: "fish.fill",
                            value: $proteinText,
                            color: Color.green.opacity(0.8)
                        )
                        MacroRow(
                            title: "Carbs",
                            systemImage: "carrot.fill",
                            value: $carbsText,
                            color: Color.orange.opacity(0.8)
                        )
                        MacroRow(
                            title: "Fat",
                            systemImage: "drop.fill",
                            value: $fatText,
                            color: Color.cyan
                        )
                    }
                    .frame(maxWidth: .infinity)

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }

                    if let viewModelError = savedMealsViewModel.errorMessage {
                        Text(viewModelError)
                            .foregroundStyle(.red)
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
                .padding()
                .onChange(of: nameText) { _, _ in clearErrors() }
                .onChange(of: descriptionText) { _, _ in clearErrors() }
                .onChange(of: caloriesText) { _, _ in clearErrors() }
                .onChange(of: proteinText) { _, _ in clearErrors() }
                .onChange(of: carbsText) { _, _ in clearErrors() }
                .onChange(of: fatText) { _, _ in clearErrors() }
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

    private var headerRow: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline).bold()
                    .foregroundStyle(.primary)
                    .padding(10)
                    .background(Color(.systemBackground), in: Circle())
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Edit Meal")
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Button {
                saveEditedMeal()
            } label: {
                Group {
                    if savedMealsViewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Save")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(.systemBackground), in: Capsule())
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(savedMealsViewModel.isLoading)
        }
    }

    private func clearErrors() {
        errorMessage = nil
        savedMealsViewModel.clearErrorMessage()
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

        let updatedMeal = SavedMeal(
            id: meal.id,
            userId: meal.userId,
            name: trimmedName,
            description: finalDescription,
            macros: Macros(calories: calories, protein: protein, carbs: carbs, fat: fat),
            createdAt: meal.createdAt,
            lastUsedAt: meal.lastUsedAt
        )

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
