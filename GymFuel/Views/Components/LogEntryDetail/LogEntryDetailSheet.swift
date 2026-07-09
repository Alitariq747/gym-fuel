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
    private var analysisExplanation: String {
        entry.feedback?.explanation.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    private var rawInputDescription: String {
        entry.rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var shouldShowRawInputDescription: Bool {
        !isSavedMealEntry && !rawInputDescription.isEmpty
    }
    private var displayTitle: String {
        let title = entry.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty { return title }

        let rawInput = entry.rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return rawInput.isEmpty ? entry.type.displayName : rawInput
    }
    private var isImageMealEntry: Bool {
        entry.type == .food && entry.source == .image
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                VStack(alignment: .leading, spacing: 16) {
                    if isImageMealEntry {
                        DetailHeroImage(entry: entry)
                    }

                    if let macros = entry.feedback?.macros, entry.type == .food {
                        DetailMacroSummaryCard(macros: macros)
                    } else if entry.type == .exercise {
                        DetailExerciseSummaryCard(entry: entry)
                    }

                    if let score = entry.feedback?.goalFitScore {
                        GoalFitProgressCard(score: score, goalType: entry.feedback?.goalType)
                    }

                    if !estimatedItems.isEmpty {
                        EstimatedItemsCard(items: estimatedItems)
                    }

                    if !analysisExplanation.isEmpty {
                        LiftEatsAnalysisCard(explanation: analysisExplanation)
                    }

                    if showsAIDetails {
                        AIDetailsCard(
                            confidenceValue: confidenceValue,
                            confidenceLevel: confidenceLevel,
                            confidenceColor: confidenceColor,
                            assumptions: assumptions,
                            isExpanded: $isAIDetailsExpanded
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
                    initialDescription: nil,
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

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isEditingRawInput {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        TextField("", text: $editedRawInput, axis: .vertical)
                            .font(.title2.weight(.bold))
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
                                    .offset(y: 5)
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
                        errorRow(aiErrorMessage)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    if shouldShowRawInputDescription {
                        Text(rawInputDescription)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                            .underline()
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(displayTitle)
                        .font(.system(size: 30, weight: .bold, design: .default))
                        .foregroundStyle(.primary)
                        .lineLimit(4)
                        .minimumScaleFactor(0.82)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let actionErrorMessage, !actionErrorMessage.isEmpty {
                errorRow(actionErrorMessage)
            }
        }
    }

    private func errorRow(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
                .foregroundStyle(Color.fuelRed)

            Text(message)
                .font(.footnote)
                .foregroundStyle(Color.fuelRed)
                .fixedSize(horizontal: false, vertical: true)
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
