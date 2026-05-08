//
//  SavedMealsPickerSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 18/04/2026.
//

import SwiftUI

struct SavedMealsPickerSheet: View {
    let userId: String
    let onSelect: (SavedMeal) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: SavedMealsViewModel

    private var content: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Loading saved meals...")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("Couldn't load saved meals")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
            } else if viewModel.savedMeals.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("No saved meals yet")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Save a meal from your profile to re-use it here.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
            } else {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.savedMeals) { meal in
                        let trimmedName = meal.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedDescription = meal.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        let displayTitle = !trimmedName.isEmpty ? trimmedName : (trimmedDescription.isEmpty ? "Saved meal" : trimmedDescription.truncated(to: 25, addEllipsis: true))

                        Button {
                            onSelect(meal)
                            dismiss()
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
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
            }
        }
    }

    var body: some View {
        ZStack {
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

                        Color.clear
                            .frame(width: 40, height: 40)
                    }

                    content
                }
                .padding()
            }
        }
        .presentationDetents([.large])
        .task {
            await viewModel.loadSavedMeals(userId: userId)
        }
    }
}

#Preview {
    SavedMealsPickerSheet(userId: "preview") { _ in }
        .environmentObject(SavedMealsViewModel())
}
