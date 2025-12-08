//
//  TodayView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    
       @State private var showingAddMeal = false
       @State private var mealDescription = ""
       @State private var caloriesText = ""
       @State private var proteinText = ""
       @State private var carbsText = ""
       @State private var fatText = ""
    
       @State private var isEstimatingWithAI = false
       @State private var aiErrorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading today…")
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 8) {
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                        Button("Retry") {
                            viewModel.loadToday()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if let log = viewModel.dayLog {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Day type selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Day type")
                                .font(.headline)
                            
                            HStack {
                                dayTypeChip(label: "Rest", type: "rest", current: log.dayType)
                                dayTypeChip(label: "Normal", type: "normal", current: log.dayType)
                                dayTypeChip(label: "Hard", type: "hard", current: log.dayType)
                            }
                        }
                        
                        // Date
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.dateString)
                                .font(.headline)
                            Text(log.dayType.capitalized + " day")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        // Targets
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target macros")
                                .font(.headline)
                            macroRow(label: "Calories", value: log.targetCalories)
                            macroRow(label: "Protein",  value: log.targetProtein, suffix: "g")
                            macroRow(label: "Carbs",    value: log.targetCarbs,   suffix: "g")
                            macroRow(label: "Fat",      value: log.targetFat,     suffix: "g")
                        }
                        
                        Divider()
                        
                        // Totals
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Logged so far")
                                .font(.headline)
                            macroRow(label: "Calories", value: log.totalCalories)
                            macroRow(label: "Protein",  value: log.totalProtein,  suffix: "g")
                            macroRow(label: "Carbs",    value: log.totalCarbs,    suffix: "g")
                            macroRow(label: "Fat",      value: log.totalFat,      suffix: "g")
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                              Text("Meals today")
                                  .font(.headline)
                              
                              if viewModel.meals.isEmpty {
                                  Text("No meals logged yet")
                                      .font(.subheadline)
                                      .foregroundColor(.secondary)
                              } else {
                                  ForEach(viewModel.meals, id: \.id) { meal in
                                      mealRow(meal)
                                  }
                              }
                            
                            Button {
                                       // open sheet
                                       mealDescription = ""
                                       caloriesText = ""
                                       proteinText = ""
                                       carbsText = ""
                                       fatText = ""
                                       showingAddMeal = true
                                   } label: {
                                       Label("Add meal", systemImage: "plus")
                                           .font(.subheadline)
                                   }
                                   .buttonStyle(.borderedProminent)
                                   .padding(.top, 4)
                          }
                        
                        Spacer()
                    }
                    .padding()

                } else {
                    Text("No data for today")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Today")
            .onAppear {
                if viewModel.dayLog == nil && !viewModel.isLoading {
                    viewModel.loadToday()
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                NavigationStack {
                    Form {
                        Section(header: Text("Meal")) {
                            TextField("Description", text: $mealDescription)
                                .textInputAutocapitalization(.sentences)
                        }
                        
                        Section(header: Text("Macros")) {
                            if let aiErrorMessage {
                                Text(aiErrorMessage)
                                    .font(.footnote)
                                    .foregroundColor(.red)
                            }
                            
                            TextField("Calories", text: $caloriesText)
                                .keyboardType(.numberPad)
                            TextField("Protein (g)", text: $proteinText)
                                .keyboardType(.numberPad)
                            TextField("Carbs (g)", text: $carbsText)
                                .keyboardType(.numberPad)
                            TextField("Fat (g)", text: $fatText)
                                .keyboardType(.numberPad)
                            
                            Button {
                                estimateMacrosWithAi()
                            } label: {
                                if isEstimatingWithAI {
                                    HStack {
                                        ProgressView()
                                        Text("Estimating…")
                                    }
                                } else {
                                    Label("Use AI to estimate macros", systemImage: "wand.and.stars")
                                }
                            }
                            .disabled(isEstimatingWithAI)
                        }
                    }
                    .navigationTitle("Add meal")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingAddMeal = false
                            }
                        }
                        
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                saveMeal()
                            }
                            .disabled(isEstimatingWithAI) // optional: prevent save while AI running
                        }
                    }
                }
            }

        }
    }
    
    private func saveMeal() {
        // Convert text fields to numbers (Double). If conversion fails, treat as 0.
        let calories = Double(caloriesText) ?? 0
        let protein  = Double(proteinText)  ?? 0
        let carbs    = Double(carbsText)    ?? 0
        let fat      = Double(fatText)      ?? 0
        
        viewModel.addMeal(
            description: mealDescription,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )
        
        showingAddMeal = false
    }

    private func estimateMacrosWithAi() {
        guard !mealDescription.trimmingCharacters(in: .whitespacesAndNewlines) .isEmpty else {
            aiErrorMessage = "Please enter valid meal description"
            return
        }
        
        aiErrorMessage = nil
        isEstimatingWithAI = true
        
        let dayType = viewModel.dayLog?.dayType
        let goal: String? = nil
        
        Task {
            do {
                let response = try await MealAiClient.shared.estimateMacros(description: mealDescription, goal: goal, dayType: dayType)
                await MainActor.run {
                    caloriesText = String(Int(response.calories))
                    proteinText = String(Int(response.protein))
                    carbsText = String(Int(response.carbs))
                    fatText = String(Int(response.fat))
                    
                    isEstimatingWithAI = false
                }
            } catch {
                await MainActor.run {
                    aiErrorMessage = error.localizedDescription
                    isEstimatingWithAI = false
                }
            }
        }
        
    }
    
    private func mealRow(_ meal: Meal) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(meal.description.isEmpty ? "Meal" : meal.description)
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 12) {
                Text("\(Int(meal.calories)) kcal")
                Text("P \(Int(meal.protein))g")
                Text("C \(Int(meal.carbs))g")
                Text("F \(Int(meal.fat))g")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    
    // MARK: - Small helper view
    
    private func macroRow(label: String, value: Double, suffix: String = "") -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(Int(value))\(suffix)")
                .foregroundColor(.secondary)
        }
        .font(.subheadline)
    }
    
    private func dayTypeChip(label: String, type: String, current: String) -> some View {
         let isSelected = (type == current)
         
         return Button {
             viewModel.setDayType(type)
         } label: {
             Text(label)
                 .font(.subheadline)
                 .padding(.vertical, 6)
                 .padding(.horizontal, 12)
                 .background(
                     RoundedRectangle(cornerRadius: 12)
                         .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                 )
                 .overlay(
                     RoundedRectangle(cornerRadius: 12)
                         .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
                 )
         }
         .buttonStyle(.plain)
     }
}

#Preview {
    TodayView()
}

