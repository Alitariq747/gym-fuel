//
//  EditMacrosSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 17/12/2025.
//

import SwiftUI

struct EditMacrosSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let originalDescription: String
    let parsed: ParsedMeal
    let mealTime: Date
    
    let onCommit: (String, ParsedMeal, Date) -> Void
    
      @State private var descriptionText: String = ""
      @State private var caloriesText: String = ""
      @State private var proteinText: String = ""
      @State private var carbsText: String = ""
      @State private var fatText: String = ""
      @State private var localMealTime: Date = Date()

      @State private var errorMessage: String?
    
    @State private var showTimePicker: Bool = false
    private let timePickerAnimation = Animation.easeInOut(duration: 0.35)
    
    var body: some View {

        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    HStack(alignment: .center, spacing: 12) {
                        Button {
                            dismiss()
                        } label: {
                            Text("X")
                                .font(.headline).bold()
                                .foregroundStyle(Color(.systemGray))
                                .padding(10)
                                .background(Color.white.opacity(0.9), in: Circle())
                                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                        }
                        Spacer()
                        
                        Button {
                            saveAndCommit()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.headline).bold()
                                .foregroundStyle(Color(.systemGray))
                                .padding(8)
                                .background(Color.white.opacity(0.9), in: Circle())
                                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                        }
                        
                    }
                    
                    VStack(spacing: 0) {
                        Text("Meal Description")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                    
                    TextEditor(text: $descriptionText)
                        .font(.system(size: 18, weight: .regular))
                        .frame(minHeight: 80)
                        .foregroundStyle(.primary)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                    
                    Text("Nutrition")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.secondary)
                    
                    // HStack for Calories
                    
                    VStack(spacing: 12) {
                        MacroRow(title: "Calories", systemImage: "flame.fill", value: $caloriesText, color: Color.liftEatsCoral)
                        MacroRow(title: "Protein", systemImage: "fish.fill", value: $proteinText, color: Color.green.opacity(0.8))
                        MacroRow(title: "Carbs", systemImage: "carrot.fill", value: $carbsText, color: Color.orange.opacity(0.8))
                        MacroRow(title: "fat", systemImage: "drop.fill", value: $fatText, color: Color.cyan)
                    }
                    .frame(maxWidth: .infinity)
   
                    
                    // VSTack for time
                    VStack(alignment: .leading, spacing: 8) {
                        
                        // Header row
                        HStack(spacing: 8) {
                            Image(systemName: showTimePicker ? "x.circle" : "pencil")
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(.black)
                            
                            Text("Edit Time ?")
                                .font(.subheadline.weight(.semibold))
                            
                            Spacer()
                            
                            // small text preview of selected time
                            Text(localMealTime, style: .time)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Actual time picker
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
                    
                }
                .padding()
            }
            .onAppear {
                if descriptionText.isEmpty {
                    descriptionText = originalDescription
                    caloriesText = String(Int(parsed.calories))
                    proteinText  = String(Int(parsed.protein))
                    carbsText    = String(Int(parsed.carbs))
                    fatText      = String(Int(parsed.fat))
                    localMealTime = mealTime
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }

    }
    
    private func saveAndCommit() {
        guard
            let calories = Double(caloriesText),
            let protein = Double(proteinText),
            let carbs = Double(carbsText),
            let fat = Double(fatText)
                else {
            errorMessage = "Please fill in all fields"
            return
        }
        let updatedParsed = ParsedMeal(
                 name: parsed.name,
                 calories: calories,
                 protein: protein,
                 carbs: carbs,
                 fat: fat,
                 confidence: parsed.confidence,
                 warnings: parsed.warnings,
                 notes: parsed.notes,
                 assumptions: parsed.assumptions
             )

             // Call back into ReviewMealSheet → AddMealFlowSheet → DayLogViewModel
             onCommit(descriptionText, updatedParsed, localMealTime)
        
        
    }
}

#Preview {
    
    ZStack {
        AppBackground()
        EditMacrosSheet(originalDescription: "Egg whites omlette", parsed: demo, mealTime: Date(), onCommit: { _,_,_ in print("Save")})
    }
}
