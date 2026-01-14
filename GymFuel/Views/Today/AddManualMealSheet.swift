//
//  AddManualMealSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 14/01/2026.
//

import SwiftUI

struct AddManualMealSheet: View {
    @ObservedObject var dayLogViewModel: DayLogViewModel
    let dayDate: Date

    @Environment(\.dismiss) private var dismiss

    // Text fields
    @State private var descriptionText: String = ""
    @State private var caloriesText: String = ""
    @State private var proteinText: String = ""
    @State private var carbsText: String = ""
    @State private var fatText: String = ""

    // Time
    @State private var localMealTime: Date = Date()
    @State private var showTimePicker: Bool = false

    // Error
    @State private var errorMessage: String?

    private let timePickerAnimation = Animation.easeInOut(duration: 0.35)

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
                                .font(.headline).bold()
                                .foregroundStyle(Color(.systemGray))
                                .padding(10)
                                .background(Color.white.opacity(0.9), in: Circle())
                                .shadow(color: Color.black.opacity(0.12),
                                        radius: 6, x: 0, y: 3)
                        }

                        Spacer()

                        Button {
                            saveAndAdd()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.headline).bold()
                                .foregroundStyle(Color(.systemGray))
                                .padding(8)
                                .background(Color.white.opacity(0.9), in: Circle())
                                .shadow(color: Color.black.opacity(0.12),
                                        radius: 6, x: 0, y: 3)
                        }
                    }

                    // Description label
                    VStack(spacing: 0) {
                        Text("Meal Description")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.secondary)
                    }

                    // Description editor
                    TextEditor(text: $descriptionText)
                        .font(.system(size: 18, weight: .regular))
                        .frame(minHeight: 80)
                        .foregroundStyle(.primary)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 14)
                        .background(
                            Color.white.opacity(0.85),
                            in: RoundedRectangle(cornerRadius: 20)
                        )
                        .shadow(color: Color.black.opacity(0.12),
                                radius: 6, x: 0, y: 3)

                    // Nutrition label
                    Text("Nutrition")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.secondary)

                    // Macro fields – reuse your MacroRow
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

                    // Time card
                    VStack(alignment: .leading, spacing: 8) {

                        // Header row
                        HStack(spacing: 8) {
                            Image(systemName: showTimePicker ? "x.circle" : "pencil")
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(.black)

                            Text("Meal time")
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
                            .transition(
                                .opacity.combined(with: .move(edge: .top))
                            )

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
                    .shadow(color: Color.black.opacity(0.12),
                            radius: 6, x: 0, y: 3)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(timePickerAnimation) {
                            showTimePicker.toggle()
                        }
                    }
                    .animation(timePickerAnimation, value: showTimePicker)

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                // Anchor the time to `dayDate` + current clock time
                localMealTime = combine(date: dayDate, time: Date())
            }
        }
    }


    private func saveAndAdd() {
        guard !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please add a short description."
            return
        }

        guard
            let calories = Double(caloriesText),
            let protein = Double(proteinText),
            let carbs   = Double(carbsText),
            let fat     = Double(fatText)
        else {
            errorMessage = "Please enter valid numbers for all macros."
            return
        }

        errorMessage = nil

        let macros = Macros(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )

        Task {
            await dayLogViewModel.addMeal(
                description: descriptionText,
                macros: macros,
                loggedAt: localMealTime
            )
            dismiss()
        }
    }


    private func combine(date: Date, time: Date) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        let timeComps = cal.dateComponents([.hour, .minute], from: time)
        comps.hour = timeComps.hour
        comps.minute = timeComps.minute
        return cal.date(from: comps) ?? date
    }
}

#Preview {
    ZStack {
        AppBackground()
        AddManualMealSheet(
            dayLogViewModel: DayLogViewModel(profile: dummyProfile),
            dayDate: Date()
        )
    }
}

