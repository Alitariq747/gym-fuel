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
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 12) {
                        premiumField("fork.knife", title: "Meal name", text: $nameText, color: .fuelOrange)
                        premiumField("text.alignleft", title: "Description", text: $descriptionText, color: .fuelBlue, lineLimit: 3...6)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Macros", systemImage: "chart.bar.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        macroField("Calories", emoji: "🔥", text: $caloriesText, color: .fuelOrange)
                        macroField("Protein", emoji: "💪", text: $proteinText, color: .fuelBlue)
                        macroField("Carbs", emoji: "⚡️", text: $carbsText, color: .fuelGreen)
                        macroField("Fat", emoji: "💧", text: $fatText, color: .pink)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                    )
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
                .padding(20)
                .onChange(of: nameText) { _, _ in clearErrors() }
                .onChange(of: descriptionText) { _, _ in clearErrors() }
                .onChange(of: caloriesText) { _, _ in clearErrors() }
                .onChange(of: proteinText) { _, _ in clearErrors() }
                .onChange(of: carbsText) { _, _ in clearErrors() }
                .onChange(of: fatText) { _, _ in clearErrors() }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.fuelRed)
                            .frame(width: 34, height: 34)
                            .background(Color.fuelRed.opacity(0.10), in: Circle())
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
                                .foregroundStyle(canCreate ? Color.white : Color.secondary)
                                .frame(width: 34, height: 34)
                                .background(canCreate ? Color.fuelGreen : Color(.tertiarySystemFill), in: Circle())
                                .shadow(color: Color.fuelGreen.opacity(canCreate ? 0.24 : 0), radius: 10, y: 5)
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

    private func premiumField(_ systemImage: String, title: String, text: Binding<String>, color: Color, lineLimit: ClosedRange<Int>? = nil) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.12), in: Circle())
            Group {
                if let lineLimit {
                    TextField(title, text: text, axis: .vertical)
                        .lineLimit(lineLimit)
                } else {
                    TextField(title, text: text, axis: .vertical)
                }
            }
            .font(.subheadline.weight(.medium))
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func macroField(_ title: String, emoji: String, text: Binding<String>, color: Color) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.12), in: Circle())
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.subheadline.weight(.bold))
                .frame(width: 74)
        }
        .padding(12)
        .background(Color(.systemBackground).opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: color.opacity(0.08), radius: 10, y: 5)
        .shadow(color: Color.black.opacity(0.035), radius: 6, y: 3)
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
