//
//  AddSavedMealSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/03/2026.
//

import SwiftUI

struct AddSavedMealSheet: View {
    @EnvironmentObject private var savedMealsViewModel: SavedMealsViewModel
    @EnvironmentObject private var authManager: FirebaseAuthManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var nameText: String = ""
    @State private var descriptionText: String = ""
    @State private var caloriesText: String = ""
    @State private var proteinText: String = ""
    @State private var carbsText: String = ""
    @State private var fatText: String = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
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

                        Text("Add Meal")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Spacer()

                        Button {
                            createSavedMeal()
                        } label: {
                            Group {
                                if savedMealsViewModel.isLoading {
                                    ProgressView()
                                } else {
                                    Text("Create")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground), in: Capsule())
                            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                        .disabled(savedMealsViewModel.isLoading)
                    }

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
    }

    private func clearErrors() {
        errorMessage = nil
        savedMealsViewModel.clearErrorMessage()
    }

    private func createSavedMeal() {
        guard let uid = authManager.user?.uid else { return }

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

        let macros = Macros(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )

        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDescription = trimmedDescription.isEmpty ? nil : trimmedDescription

        let savedMeal = SavedMeal(
            id: UUID().uuidString,
            userId: uid,
            name: trimmedName,
            description: finalDescription,
            macros: macros
        )

        Task {
            let didSave = await savedMealsViewModel.saveSavedMeal(savedMeal)
            if didSave {
                dismiss()
            }
        }
    }
}

#Preview {
    AddSavedMealSheet()
        .environmentObject(SavedMealsViewModel())
        .environmentObject(FirebaseAuthManager())
}
