import SwiftUI

struct LogEntryDetailSheet: View {
    let entry: LogEntry
    @EnvironmentObject private var savedMealsViewModel: SavedMealsViewModel
    var isPerformingAction: Bool = false
    var aiErrorMessage: String? = nil
    var actionErrorMessage: String? = nil
    var onClearAIError: (() -> Void)? = nil
    var onClearActionError: (() -> Void)? = nil
    var onSaveMacros: ((Macros) -> Void)? = nil
    var onSaveCaloriesBurned: ((Double) -> Void)? = nil
    var onSaveLoggedAt: ((Date) -> Void)? = nil
    var onDeleteEntry: (() -> Void)? = nil
    var onUseAIAgain: ((String) -> Void)? = nil
    var onSaveMeal: ((String, String?, Macros) -> Void)? = nil

    @State private var showManualEditSheet = false
    @State private var showTimeEditSheet = false
    @State private var showSaveMealSheet = false
    @State private var showSavedMealToast = false
    @State private var showDeleteConfirmation = false
    @State private var isAIDetailsExpanded = false
    @State private var isEditingRawInput = false
    @State private var editedRawInput = ""
    @State private var editedLoggedAt = Date()
    @FocusState private var isRawInputFocused: Bool
    
    private var canEditManually: Bool {
        entry.feedback?.macros != nil || entry.feedback?.estimatedCalories != nil
    }
    private var isSavedMealEntry: Bool {
        entry.source == .savedMeal
    }
    private var saveableMealMacros: Macros? {
        guard entry.status == .succeeded,
              entry.type == .food,
              let macros = entry.feedback?.macros
        else {
            return nil
        }

        return macros
    }
    private var canSaveAsMeal: Bool {
        saveableMealMacros != nil
    }
    private var confidenceValue: Double? {
        entry.feedback?.confidence
    }
    private var confidenceLevel: String {
        guard let confidenceValue else { return "Unknown" }
        if confidenceValue >= 0.8 { return "High" }
        if confidenceValue >= 0.6 { return "Moderate" }
        return "Low"
    }
    private var confidenceColor: Color {
        guard let confidenceValue else { return .secondary }
        if confidenceValue >= 0.8 { return .fuelGreen }
        if confidenceValue >= 0.6 { return .fuelOrange }
        return .fuelRed
    }
    private var assumptions: [String] {
        entry.feedback?.assumptions ?? []
    }
    private var estimatedItems: [EstimatedItem] {
        entry.feedback?.estimatedItems ?? []
    }
    private var hasExpandableAIDetails: Bool {
        !assumptions.isEmpty
    }
    private var showsAIDetails: Bool {
        confidenceValue != nil || hasExpandableAIDetails
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    if isEditingRawInput {
                        HStack(alignment: .top, spacing: 10) {
                            TextField("", text: $editedRawInput, axis: .vertical)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .textFieldStyle(.plain)
                                .focused($isRawInputFocused)
                                .lineLimit(2...6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .disabled(isPerformingAction)
                                .overlay(alignment: .bottomLeading) {
                                    Rectangle()
                                        .fill(Color.primary)
                                        .frame(height: 1)
                                        .offset(y: 4)
                                }

                            if isPerformingAction {
                                ProgressView()
                                    .controlSize(.small)
                                    .frame(width: 24, height: 24, alignment: .top)
                            } else {
                                VStack(spacing: 14) {
                                    Button {
                                        onClearAIError?()
                                        editedRawInput = entry.rawInput
                                        isEditingRawInput = false
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.fuelRed)
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        let trimmedText = editedRawInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                        guard !trimmedText.isEmpty else { return }
                                        onUseAIAgain?(trimmedText)
                                    } label: {
                                        Image(systemName: "checkmark")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(
                                                editedRawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                                ? .secondary
                                                : Color.fuelBlue
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(editedRawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }
                        }

                        if let aiErrorMessage, !aiErrorMessage.isEmpty {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.fuelRed)

                                Text(aiErrorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(Color.fuelRed)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    } else {
                        Text(entry.rawInput)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .underline()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let actionErrorMessage, !actionErrorMessage.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(Color.fuelRed)

                            Text(actionErrorMessage)
                                .font(.footnote)
                                .foregroundStyle(Color.fuelRed)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    TimelineEntryRow(entry: entry, showsChevron: false)

                    if let explanation = entry.feedback?.explanation, !explanation.isEmpty {
                        LiftEatsAnalysisCard(explanation: explanation)
                    }

                    if !estimatedItems.isEmpty {
                        EstimatedItemsCard(items: estimatedItems)
                    }

                    if showsAIDetails {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI Details")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            if let confidenceValue {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .stroke(confidenceColor.opacity(0.18), lineWidth: 5)

                                        Circle()
                                            .trim(from: 0, to: confidenceValue)
                                            .stroke(
                                                confidenceColor,
                                                style: StrokeStyle(lineWidth: 5, lineCap: .round)
                                            )
                                            .rotationEffect(.degrees(-90))

                                        Text("\(Int((confidenceValue * 100).rounded()))")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.primary)
                                    }
                                    .frame(width: 42, height: 42)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Confidence level")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(confidenceLevel)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(confidenceColor)
                                    }

                                    Spacer()

                                    if hasExpandableAIDetails {
                                        Button {
                                            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                                isAIDetailsExpanded.toggle()
                                            }
                                        } label: {
                                            Image(systemName: isAIDetailsExpanded ? "chevron.up" : "chevron.down")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                                .frame(width: 30, height: 30)
                                                .background(Color(.secondarySystemBackground), in: Circle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            if isAIDetailsExpanded && hasExpandableAIDetails {
                                VStack(alignment: .leading, spacing: 12) {
                                    Divider()

                                    if !assumptions.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "questionmark.circle.fill")
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(Color.fuelBlue)

                                                Text("Assumptions")
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(.secondary)
                                            }

                                            ForEach(assumptions, id: \.self) { assumption in
                                                HStack(alignment: .center, spacing: 8) {
                                                    Text("-")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)

                                                    Text(assumption)
                                                        .font(.footnote)
                                                        .foregroundStyle(.secondary)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                }
                                            }
                                        }
                                    }
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding(14)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(.systemBackground),
                                    Color(.secondarySystemBackground),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color(.quaternaryLabel).opacity(0.55), lineWidth: 1)
                        )
                    }
                }
                .opacity(isPerformingAction ? 0.5 : 1)
                .allowsHitTesting(!isPerformingAction)
            }
            .padding()
        }
        .overlay(alignment: .bottom) {
            if showSavedMealToast {
                savedMealToast
                    .padding(.bottom, 18)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit Manually", systemImage: "slider.horizontal.3") {
                        onClearActionError?()
                        showManualEditSheet = true
                    }
                    .disabled(!canEditManually)
                    Divider()
                    Button("Edit Time", systemImage: "clock") {
                        onClearActionError?()
                        showTimeEditSheet = true
                    }
                    .disabled(isPerformingAction)
                    if !isSavedMealEntry {
                        Divider()
                        Button("Edit with AI", systemImage: "sparkles") {
                            onClearAIError?()
                            editedRawInput = entry.rawInput
                            isEditingRawInput = true
                        }
                        .disabled(isPerformingAction)
                        Divider()
                        Button("Save Meal", systemImage: "bookmark") {
                            onClearActionError?()
                            showSaveMealSheet = true
                        }
                        .disabled(!canSaveAsMeal || isPerformingAction)
                    }
                    Divider()
                    Button("Delete Entry", systemImage: "trash", role: .destructive) {
                        onClearActionError?()
                        showDeleteConfirmation = true
                    }
                    .disabled(isPerformingAction)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
//                        .padding(10)
//                        .background(Color(.secondarySystemBackground), in: Circle())
                }
                .disabled(isPerformingAction)
            }
        }
        .sheet(isPresented: $showManualEditSheet) {
            if let macros = entry.feedback?.macros {
                ManualMacroEditSheet(
                    initialMacros: macros,
                    onSave: onSaveMacros
                )
            } else if let estimatedCalories = entry.feedback?.estimatedCalories {
                ManualMacroEditSheet(
                    initialCaloriesBurned: estimatedCalories,
                    onSave: onSaveCaloriesBurned
                )
            }
        }
        .sheet(isPresented: $showTimeEditSheet) {
            VStack(spacing: 16) {
                    Text("Edit Time")
                        .font(.headline.weight(.semibold))
                        .padding(.top, 8)
                     DatePicker(
                    "Logged time",
                    selection: $editedLoggedAt,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Button {
                    onSaveLoggedAt?(mergedLoggedAt(from: editedLoggedAt))
                    showTimeEditSheet = false
                } label: {
                    Text("Save Time")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isPerformingAction)
            }
            .padding(24)
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
            .onAppear {
                editedLoggedAt = entry.loggedAt
            }
        }
        .sheet(isPresented: $showSaveMealSheet) {
            if let saveableMealMacros {
                SaveLoggedMealSheet(
                    initialName: entry.title,
                    initialDescription: entry.detail ?? entry.rawInput,
                    macros: saveableMealMacros
                ) { name, description, macros in
                    let meal = SavedMeal(id: UUID().uuidString, userId: entry.userId, name: name, description: description, macros: macros)
                    Task {
                        if await savedMealsViewModel.saveSavedMeal(meal) {
                            showSaveMealSheet = false
                            presentSavedMealToast()
                        }
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete this entry?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Entry", role: .destructive) {
                onDeleteEntry?()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove the selected entry from your timeline.")
        }
        .onAppear {
            editedRawInput = entry.rawInput
        }
        .onChange(of: entry.rawInput) { _, newValue in
            editedRawInput = newValue

            if isEditingRawInput {
                isEditingRawInput = false
                isRawInputFocused = false
            }
        }
        .onChange(of: isEditingRawInput) { _, isEditing in
            isRawInputFocused = isEditing
        }
    }

    private var savedMealToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.fuelGreen)
            Text("Meal saved")
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.systemBackground).opacity(0.96), in: Capsule())
        .shadow(color: Color.fuelGreen.opacity(0.16), radius: 14, y: 7)
    }

    private func presentSavedMealToast() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            showSavedMealToast = true
        }
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeOut(duration: 0.2)) {
                showSavedMealToast = false
            }
        }
    }

    private func mergedLoggedAt(from selectedTime: Date, calendar: Calendar = .current) -> Date {
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        return calendar.date(
            bySettingHour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: entry.loggedAt
        ) ?? entry.loggedAt
    }
}

private struct EstimatedItemsCard: View {
    let items: [EstimatedItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estimated Breakdown")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(items, id: \.self) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        if !item.quantity.isEmpty {
                            Text(item.quantity)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !item.estimatedComponents.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(item.estimatedComponents, id: \.self) { component in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("-")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text("\(component.name): \(component.estimatedAmount)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.quaternaryLabel).opacity(0.55), lineWidth: 1)
        )
    }
}

private struct LiftEatsAnalysisCard: View {
    let explanation: String
    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }

    private var cardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(.quaternaryLabel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image("LiftEatsWelcomeIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text("LiftEats Analysis")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(explanation)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(cardStroke, lineWidth: 1))
    }
}

private struct PreviewSavedMealService: SavedMealService {
    func fetchSavedMeals(for userId: String) async throws -> [SavedMeal] { [] }
    func saveMeal(_ meal: SavedMeal) async throws { }
    func updateMeal(_ meal: SavedMeal) async throws { }
    func deleteMeal(userId: String, mealId: String) async throws { }
}

#Preview {
    NavigationStack {
        LogEntryDetailSheet(
            entry: LogEntry(
                userId: "preview",
                type: .food,
                title: "Chicken Bowl",
                rawInput: "Chicken bowl with some salad and fruits with one cup of boiled rice",
                feedback: LogEntryFeedback(
                    explanation: "High protein and moderate calories fit well into the day.",
                    assumptions: [
                        "Rice was treated as roughly 1 cooked cup.",
                        "Salad dressing was assumed to be light and not separately logged.",
                    ],
                    confidence: 0.72,
                    estimatedCalories: nil,
                    macros: Macros(calories: 620, protein: 44, carbs: 52, fat: 20),
                    goalFitScore: 78,
                    estimatedItems: nil
                )
            )
        )
        .environmentObject(SavedMealsViewModel(service: PreviewSavedMealService()))
    }
}
