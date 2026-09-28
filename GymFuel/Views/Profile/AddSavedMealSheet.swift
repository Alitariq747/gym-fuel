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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Create saved meal")
                            .font(.title3.weight(.bold))
                        Text("Build a reusable meal with clean macros for quick logging.")
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
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.circaInk2)
                            .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                            .background(Color.circaWell, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { createSavedMeal() } label: {
                        if savedMealsViewModel.isLoading {
                            ProgressView()
                                .frame(width: 34, height: 34)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(canCreate ? Color.circaPaperTop : Color.circaInk3)
                                .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                                .background(canCreate ? Color.circaInk : Color.circaSunken, in: Circle())
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!canCreate || savedMealsViewModel.isLoading)
                }
            }
        }
        .presentationDetents([.large])
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

    private var canCreate: Bool {
        let hasName = !nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let macros = editedMacros
        return hasName && (macros.calories > 0 || macros.protein > 0 || macros.carbs > 0 || macros.fat > 0)
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
