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

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading saved meals...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundStyle(.secondary)
                } else if viewModel.savedMeals.isEmpty {
                    Text("No saved meals yet").foregroundStyle(.secondary)
                } else {
                    List(viewModel.savedMeals) { meal in
                        Button {
                            onSelect(meal)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(meal.name).foregroundStyle(.primary)
                                Text("\(Int(meal.macros.calories)) kcal")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Saved Meals")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await viewModel.loadSavedMeals(userId: userId)
        }
    }
}

#Preview {
    SavedMealsPickerSheet(userId: "preview") { _ in }
        .environmentObject(SavedMealsViewModel())
}
