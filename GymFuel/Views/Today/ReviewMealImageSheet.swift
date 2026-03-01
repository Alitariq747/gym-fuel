//
//  ReviewMealImageSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 21/02/2026.
//

import SwiftUI

struct ReviewMealImageSheet: View {
    let image: UIImage
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
                    HStack(alignment: .center, spacing: 8) {
                        Text("AI Details")
                            .font(.subheadline).bold()
                            .foregroundStyle(.primary)
                        Spacer()

                        Button {
                            showDiscardAlert = true
                        } label: {
                            Image(systemName: "xmark")
                                .font(.headline).bold()
                                .foregroundStyle(Color(.systemGray))
                                .padding(10)
                                .background(Color(.systemBackground), in: Circle())
                                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                        }
                    }

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)

                    Text(parsed.name ?? "")
                        .font(.title2).bold()
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(-4)

                    VStack(alignment: .center, spacing: 10) {
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
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)

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
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)

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
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: showTimePicker ? "x.circle" : "pencil")
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(.black)

                            Text("When did you eat this?")
                                .font(.subheadline.weight(.semibold))

                            Spacer()

                            Text(mealTime, style: .time)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

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

                    AIDetailsSection(parsed: parsed)

                    HStack(alignment: .center) {
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
                EditMacrosSheet(
                    originalDescription: originalDescription,
                    parsed: parsed,
                    mealTime: mealTime
                ) { newDescription, newParsed, newMealTime in
                    onSave(newDescription, newParsed, newMealTime)
                }
            }
        }
        .confirmationDialog(
            "Skip logging this meal?",
            isPresented: $showDiscardAlert,
            titleVisibility: .visible
        ) {
            Button("Skip meal", role: .destructive) {
                onDiscard()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("If you skip, this meal will not be saved to your log.")
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ReviewMealImageSheet(
        image: UIImage(systemName: "photo") ?? UIImage(),
        originalDescription: "Photo meal",
        parsed: demo,
        mealTime: Date(),
        onSave: { _, _, _ in print("save") },
        onDiscard: { print("") }
    )
}
