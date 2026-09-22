import SwiftUI

struct SavedMealsSheet: View {
    @EnvironmentObject private var savedMealsViewModel: SavedMealsViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appColorSchemePreference") private var colorSchemePreference = AppColorSchemePreference.system.rawValue
    @State private var showAddSavedMealSheet = false
    @State private var selectedMeal: SavedMeal?
    @State private var searchText = ""

    private var preferredColorScheme: ColorScheme? {
        AppColorSchemePreference(rawValue: colorSchemePreference)?.colorScheme
    }

    private var matchingMeals: [SavedMeal] {
        guard !searchText.isEmpty else { return savedMealsViewModel.savedMeals }
        return savedMealsViewModel.savedMeals.filter { $0.searchText.localizedStandardContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Meals you can reuse. A saved estimate keeps its assumptions and any portions you corrected.")
                        .font(.circaBody)
                        .foregroundStyle(Color.circaInk2)

                    if let error = savedMealsViewModel.errorMessage {
                        CircaCard(.danger) {
                            Text(error).font(.circaBody)
                        }
                    }

                    if savedMealsViewModel.savedMeals.isEmpty {
                        CircaCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("No saved meals yet", systemImage: "bookmark")
                                    .font(.circaRow.weight(.semibold))
                                Text("Save a logged meal to keep its breakdown, or add a meal with your own totals.")
                                    .font(.circaBody)
                                    .foregroundStyle(Color.circaInk2)
                            }
                        }
                    } else if matchingMeals.isEmpty {
                        CircaCard {
                            Text("No matching meals. Try a meal name or ingredient.")
                                .font(.circaBody)
                        }
                    } else {
                        LazyVStack(spacing: Circa.Space.rowGap) {
                            ForEach(matchingMeals) { meal in
                                Button { selectedMeal = meal } label: {
                                    SavedMealCard(meal: meal, actionTitle: "Edit this saved meal")
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
                ToolbarItem(placement: .confirmationAction) {
                    Button { showAddSavedMealSheet = true } label: {
                        Label("Add meal", systemImage: "plus")
                    }
                    .foregroundStyle(Color.circaAccent)
                }
            }
            .circaPaper()
        }
        .presentationDetents([.large])
        .sheet(isPresented: $showAddSavedMealSheet) {
            AddSavedMealSheet()
                .preferredColorScheme(preferredColorScheme)
        }
        .sheet(item: $selectedMeal) { meal in
            EditSavedMealSheet(meal: meal)
                .preferredColorScheme(preferredColorScheme)
        }
    }
}

#Preview {
    let vm = SavedMealsViewModel()
    vm._setSavedMealsForPreview([.demo])
    return SavedMealsSheet().environmentObject(vm)
}
