//
//  ReviewMealSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 16/12/2025.
//

import SwiftUI

struct ReviewMealSheet: View {
    let originalDescription: String
    @State var parsed: ParsedMeal
    @State var mealTime: Date
    let onSave: (String, ParsedMeal, Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showTimePicker: Bool = false
    private let timePickerAnimation = Animation.easeInOut(duration: 0.35)
    
    @State private var showEditMacrosSheet = false
    
    let onDiscard: () -> Void
    @State private var showDiscardAlert = false

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // HStack for nutrition details and buttons
                    HStack(alignment: .center, spacing: 8) {
                        Text("AI Details")
                            .font(.subheadline).bold()
                            .foregroundStyle(.primary)
                        Spacer()
                        
                        Button {
                            showDiscardAlert = true
                        } label: {
                            Text("X")
                                .font(.headline).bold()
                                .foregroundStyle(Color(.systemGray))
                                .padding(10)
                                .background(Color.white.opacity(0.9), in: Circle())
                                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                        }
                        
                        
                    }
                    
                    Text(parsed.name ?? "")
                        .font(.title2).bold()
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(-4)
                    
                    // VStack for macros
                    VStack(alignment: .center, spacing: 10) {
                        // HStack for calories
                        HStack(alignment: .center) {
                            Image(systemName: "flame.fill")
                                .font(.title3).bold()
                                .foregroundStyle(Color.liftEatsCoral)
                            Text("\(Int(parsed.calories))")
                                .font(.title).bold()
                            Text("Total calories")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                        // Parent HStack for other three macros
                        HStack(alignment: .center, spacing: 12) {
                            VStack(spacing: 6) {
                                Text("PROTEIN")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 4) {
                                    Image(systemName: "fish.fill")
                                        .font(.system(size: 16, weight: .light))
                                        .foregroundStyle(Color.green.opacity(0.8))
                                    Text("\(Int(parsed.protein)) g")
                                        .font(.system(size: 20, weight: .semibold))
                                }
                            }
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
                            .shadow(
                                color: Color.black.opacity(0.15),
                                radius: 8,
                                x: 0, y: 4
                            )
                            // Carbs
                            VStack(spacing: 6) {
                                Text("CARBS")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 4) {
                                    Image(systemName: "carrot.fill")
                                        .font(.system(size: 16, weight: .light))
                                        .foregroundStyle(Color.orange.opacity(0.8))
                                    Text("\(Int(parsed.carbs)) g")
                                        .font(.system(size: 20, weight: .semibold))
                                }
                            }
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
                            .shadow(
                                color: Color.black.opacity(0.15),
                                radius: 8,
                                x: 0, y: 4
                            )
                            // Fats
                            VStack(spacing: 6) {
                                Text("FAT")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 4) {
                                    Image(systemName: "drop.fill")
                                        .font(.system(size: 16, weight: .light))
                                        .foregroundStyle(Color.cyan)
                                    Text("\(Int(parsed.fat)) g")
                                        .font(.system(size: 20, weight: .semibold))
                                }
                            }
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
                            .shadow(
                                color: Color.black.opacity(0.15),
                                radius: 8,
                                x: 0, y: 4
                            )
                        }
                    }
                    
                    // time row
                    VStack(alignment: .leading, spacing: 8) {
                        
                        // Header row
                        HStack(spacing: 8) {
                            Image(systemName: showTimePicker ? "x.circle" : "pencil")
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(.black)
                            
                            Text("When did you eat this?")
                                .font(.subheadline.weight(.semibold))
                            
                            Spacer()
                            
                            // small text preview of selected time
                            Text(mealTime, style: .time)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Actual time picker
                        if showTimePicker {
                            DatePicker(
                                "",
                                selection: $mealTime,
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
                    
                    
                    // ...
                    // VStack for insights
                    AIDetailsSection(parsed: parsed)
                    
                    // HStack for edit and save options
                    HStack(alignment: .center) {
                        // Edit button
                        Button {
                            showEditMacrosSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "pencil.line")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Color.liftEatsCoral)
                                Text("Unsatisfied? Edit manually")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.liftEatsCoral)
                            }
                        }
                        Spacer()
                        // Save Button
                        Button {
                            onSave(originalDescription, parsed, mealTime)
                        } label: {
                            Text("Save meal")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.liftEatsCoral, in: RoundedRectangle(cornerRadius: 28))
                                .shadow(
                                    color: Color.black.opacity(0.15),
                                    radius: 8,
                                    x: 0, y: 4
                                )
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .sheet(isPresented: $showEditMacrosSheet) {
                EditMacrosSheet(originalDescription: originalDescription, parsed: parsed, mealTime: mealTime) { newDescription, newParsed, newMealTime in
                    onSave(newDescription, newParsed, newMealTime)
                }
            }
            .alert("Skip logging this meal?", isPresented: $showDiscardAlert) {
                Button("Skip meal", role: .destructive) {
                    // User confirmed they want to skip logging → exit entire flow
                    onDiscard()
                }
                Button("Cancel", role: .cancel) {
                    // do nothing, just close the alert
                }
            }
            message: {
                Text("If you skip, this meal will not be saved to your log.")
            }
        }
    }
}



#Preview {
  
        ReviewMealSheet(originalDescription: "Eggs whites omlette", parsed: demo, mealTime: Date(), onSave: { _,_,_ in print("save")}, onDiscard: { print("")})
    
}
