//
//  SavedMealsSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/03/2026.
//

import SwiftUI

struct SavedMealsSheet: View {
    @EnvironmentObject private var savedMealsViewModel: SavedMealsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAddSavedMealSheet: Bool = false
    @State private var selectedMeal: SavedMeal?

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 12) {
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

                    Text("Saved Meals")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Button {
                        showAddSavedMealSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(8)
                            .background(Color(.systemBackground), in: Circle())
                            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }
                if savedMealsViewModel.savedMeals.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("No saved meals yet")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("Save a meal to re-use it later.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                } else {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(savedMealsViewModel.savedMeals) { meal in
                            let trimmedName = meal.name.trimmingCharacters(in: .whitespacesAndNewlines)
                            let trimmedDescription = meal.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                            let displayTitle = !trimmedName.isEmpty ? trimmedName : (trimmedDescription.isEmpty ? "Saved meal" : trimmedDescription.truncated(to: 25, addEllipsis: true))

                            Button {
                                selectedMeal = meal
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(displayTitle)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    HStack(spacing: 12) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "flame.fill")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(Color.fuelOrange)
                                            Text("\(Int(meal.macros.calories)) cal")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        HStack(spacing: 4) {
                                            Text("P:")
                                                .font(.caption)
                                                .foregroundStyle(Color.green.opacity(0.8))
                                            Text("\(Int(meal.macros.protein))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        HStack(spacing: 4) {
                                            Text("C:")
                                                .font(.caption)
                                                .foregroundStyle(Color.orange.opacity(0.8))
                                            Text("\(Int(meal.macros.carbs))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        HStack(spacing: 4) {
                                            Text("F:")
                                                .font(.caption)
                                                .foregroundStyle(Color.cyan)
                                            Text("\(Int(meal.macros.fat))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 14)
                                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
                }
                }
                .padding()
            }
        }
        .presentationDetents([.large])
        .sheet(isPresented: $showAddSavedMealSheet) {
            AddSavedMealSheet()
        }
        .sheet(item: $selectedMeal) { meal in
            EditSavedMealSheet(meal: meal)
        }
    }
}

#Preview {
    let vm = SavedMealsViewModel()
    vm._setSavedMealsForPreview([
        SavedMeal(
            id: UUID().uuidString,
            userId: "preview-user",
            name: "Chicken rice bowl",
            description: "Chicken, rice, avocado, and salsa",
            macros: Macros(calories: 620, protein: 45, carbs: 70, fat: 18)
        ),
        SavedMeal(
            id: UUID().uuidString,
            userId: "preview-user",
            name: "",
            description: "Greek yogurt with berries",
            macros: Macros(calories: 280, protein: 22, carbs: 30, fat: 6)
        )
    ])

    return SavedMealsSheet()
        .environmentObject(vm)
}
