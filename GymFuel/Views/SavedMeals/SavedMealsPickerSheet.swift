import SwiftUI

struct SavedMealsPickerSheet: View {
    let userId: String
    let onSelect: (SavedMeal) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: SavedMealsViewModel
    @State private var searchText = ""

    private var matchingMeals: [SavedMeal] {
        guard !searchText.isEmpty else { return viewModel.savedMeals }
        return viewModel.savedMeals.filter { $0.searchText.localizedStandardContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Reuse a saved meal with its saved portions and assumptions. You can adjust the new log afterward.")
                        .font(.circaBody)
                        .foregroundStyle(Color.circaInk2)

                    if viewModel.isLoading && viewModel.savedMeals.isEmpty {
                        ProgressView("Loading saved meals…")
                            .frame(maxWidth: .infinity)
                    } else if let error = viewModel.errorMessage {
                        stateCard("Couldn’t load saved meals", detail: error, symbol: "exclamationmark.triangle")
                    } else if viewModel.savedMeals.isEmpty {
                        stateCard("No saved meals yet", detail: "Save a logged meal or add one in Settings to reuse it here.", symbol: "bookmark")
                    } else if matchingMeals.isEmpty {
                        stateCard("No matching meals", detail: "Try a meal name or ingredient.", symbol: "magnifyingglass")
                    } else {
                        LazyVStack(spacing: Circa.Space.rowGap) {
                            ForEach(matchingMeals) { meal in
                                Button {
                                    onSelect(meal)
                                    dismiss()
                                } label: {
                                    SavedMealCard(meal: meal, actionTitle: "Log this saved meal")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(Circa.Space.screenMargin)
            }
            .scrollDismissesKeyboard(.interactively)
            .searchable(text: $searchText, prompt: "Find a meal or ingredient")
            .navigationTitle("Saved meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.circaAccent)
                }
            }
            .circaPaper()
        }
        .presentationDetents([.large])
        .task { await viewModel.loadSavedMeals(userId: userId) }
    }

    private func stateCard(_ title: String, detail: String, symbol: String) -> some View {
        CircaCard {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: symbol)
                    .font(.circaRow.weight(.semibold))
                Text(detail)
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
            }
        }
    }
}

#Preview {
    SavedMealsPickerSheet(userId: "preview") { _ in }
        .environmentObject(SavedMealsViewModel())
}
