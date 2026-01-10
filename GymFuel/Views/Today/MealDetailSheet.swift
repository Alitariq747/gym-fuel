//
//  MealDetailSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 20/12/2025.
//

import SwiftUI


struct MealDetailSheet: View {


    @Environment(\.dismiss) private var dismiss


    let meal: Meal
    let onSave: (Meal) -> Void
    let onDelete: () -> Void

    @State private var descriptionText: String
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var carbsText: String
    @State private var fatText: String
    @State private var localMealTime: Date

    @State private var errorMessage: String?
    @State private var showTimePicker: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    private let timePickerAnimation = Animation.easeInOut(duration: 0.35)


    init(
        meal: Meal,
        onSave: @escaping (Meal) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.meal = meal
        self.onSave = onSave
        self.onDelete = onDelete

        _descriptionText = State(initialValue: meal.description)
        _caloriesText    = State(initialValue: String(Int(meal.macros.calories)))
        _proteinText     = State(initialValue: String(Int(meal.macros.protein)))
        _carbsText       = State(initialValue: String(Int(meal.macros.carbs)))
        _fatText         = State(initialValue: String(Int(meal.macros.fat)))
        _localMealTime   = State(initialValue: meal.loggedAt)
    }


    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Top bar: close + save
                    HStack(alignment: .center, spacing: 12) {
                        Button {
                            dismiss()
                        } label: {
                            Text("X")
                                .font(.headline.bold())
                                .foregroundStyle(Color(.systemGray))
                                .padding(10)
                                .background(Color.white.opacity(0.9), in: Circle())
                                .shadow(color: Color.black.opacity(0.12),
                                        radius: 6, x: 0, y: 3)
                        }

                        Spacer()

                        Button {
                            save()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.headline.bold())
                                .foregroundStyle(Color(.systemGray))
                                .padding(8)
                                .background(Color.white.opacity(0.9), in: Circle())
                                .shadow(color: Color.black.opacity(0.12),
                                        radius: 6, x: 0, y: 3)
                        }
                    }

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            TextEditor(text: $descriptionText)
                                .font(.system(size: 18, weight: .regular))
                                .frame(minHeight: 80)
                                .foregroundStyle(.primary)
                                .scrollContentBackground(.hidden)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
                                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                        }



                        // Nutrition block
                        Text("Nutrition")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.secondary)

                        VStack(spacing: 12) {
                            MacroRow(
                                title: "Calories",
                                systemImage: "flame.fill",
                                value: $caloriesText,
                                color: Color.liftEatsCoral
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
                    
                    // VStack for time
                    VStack(alignment: .leading, spacing: 8) {
                        
                    
                        HStack(spacing: 8) {
                            Image(systemName: showTimePicker ? "x.circle" : "pencil")
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(.black)
                            
                            Text("Edit Time ?")
                                .font(.subheadline.weight(.semibold))
                            
                            Spacer()
                            
                          
                            Text(localMealTime, style: .time)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        // time picker
                        if showTimePicker {
                            DatePicker(
                                "",
                                selection: $localMealTime,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .datePickerStyle(.wheel)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            
                            Text("We use the time you had your meal to provide better insights with your fuel score.")
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.85))
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(timePickerAnimation) {
                            showTimePicker.toggle()
                        }
                    }
                    .animation(timePickerAnimation, value: showTimePicker)

                        if let error = errorMessage {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.footnote)
                        }

                        // Delete button
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
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .confirmationDialog(
            "Delete this meal? This action can not be reversed",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: - Save Logic

    private func save() {
        guard
            let calories = Double(caloriesText),
            let protein  = Double(proteinText),
            let carbs    = Double(carbsText),
            let fat      = Double(fatText)
        else {
            errorMessage = "Please enter valid numbers for all macros."
            return
        }

        let updatedMacros = Macros(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )

        var updatedMeal = meal
        updatedMeal.description = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedMeal.loggedAt = localMealTime
        updatedMeal.macros = updatedMacros

        onSave(updatedMeal)
    }
}



#Preview {
    MealDetailSheet(meal: Meal.demoMeals(forTrainingDay: DayLog.demoTrainingDay)[0], onSave: { _ in print("")}, onDelete: { print("")})
}
