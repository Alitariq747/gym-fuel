//
//  ProfileEditorView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 29/01/2026.
//

import SwiftUI

struct ProfileEditorView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appColorSchemePreference") private var colorSchemePreference = "system"
    @Binding var draft: UserProfileDraft
    let email: String?

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    // age
    @State private var ageText: String = ""
    @FocusState private var isAgeFieldFocused: Bool
    private func syncAgeTextFromDraft() {
        ageText = draft.age.map(String.init) ?? ""
    }

    private func applyAgeTextToDraft(_ newValue: String) {
        let digits = newValue.filter(\.isNumber)
        ageText = digits
        
        // keep age to sane number
        if let value = Int(digits) {
            draft.age = min(max(value, 10), 100)
        }

        if digits.isEmpty {
            draft.age = nil
        } else {
            draft.age = Int(digits)
        }
    }
    
    // gender
    @State private var showGenderSheet = false

    private var genderTitle: String {
        draft.gender.displayName
    }

    // goal and activity
    @State private var showGoalSheet = false
    @State private var showActivitySheet = false

    private var goalTitle: String {
        draft.goalType?.displayName ?? "Set"
    }

    private var activityLevelTitle: String {
        draft.nonTrainingActivityLevel?.shortDisplayName ?? "Set"
    }

    // Height
    @State private var isEditHeightPresented = false

    private var heightPrimaryText: String {
        guard let cm = draft.heightCm, cm > 0 else { return "Set" }
        return "\(Int(cm.rounded())) cm"
    }
    
    // Weight
    @State private var isEditWeightPresented = false
    
    private var weightPrimaryText: String {
        guard let kg = draft.weightKg, kg > 0 else { return "Set" }
        return "\(Int(kg.rounded())) kg"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            profileHeader

            VStack(spacing: 12) {
                sectionHeader(title: "Body Metrics", systemImage: "figure.stand")
                bodyMetricsCard
            }

            VStack(spacing: 12) {
                sectionHeader(title: "Targets", systemImage: "scope")
                targetsCard
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            isAgeFieldFocused = false
        }
        .onAppear {
            syncAgeTextFromDraft()
        }
        .sheet(isPresented: $isEditHeightPresented) {
            NavigationStack {
                EditHeightSheet(heightCm: $draft.heightCm)
            }
            .preferredColorScheme(preferredColorScheme)
            .presentationDetents([.large])
        }
        .sheet(isPresented: $isEditWeightPresented) {
            NavigationStack {
                EditWeightSheet(weightKg: $draft.weightKg)
            }
            .preferredColorScheme(preferredColorScheme)
        }
        .sheet(isPresented: $showGoalSheet) {
            goalPickerSheet
                .preferredColorScheme(preferredColorScheme)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showActivitySheet) {
            activityPickerSheet
                .preferredColorScheme(preferredColorScheme)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showGenderSheet) {
            genderPickerSheet
                .preferredColorScheme(preferredColorScheme)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.9),
                                    Color.accentColor.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    Text(initials)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    TextField("Your name", text: $draft.name)
                        .font(.title2.weight(.semibold))
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                    Text(email ?? "—")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.primary.opacity(0.3))
            }
        }
        .padding(18)
        .background(cardBackground)
    }

    private var bodyMetricsCard: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                rowLabel("Age", systemImage: "calendar")
                Spacer()
                TextField("—", text: $ageText)
                    .font(.callout.weight(.semibold))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .focused($isAgeFieldFocused)
                    .onChange(of: ageText) { _, newValue in
                        applyAgeTextToDraft(newValue)
                    }
            }
            Divider()
            rowButton(
                title: "Gender",
                systemImage: "person.fill",
                value: genderTitle,
                isPlaceholder: false
            ) {
                showGenderSheet = true
            }
            Divider()
            rowButton(
                title: "Height",
                systemImage: "ruler",
                value: heightPrimaryText,
                isPlaceholder: heightPrimaryText == "Set"
            ) {
                isEditHeightPresented = true
            }
            Divider()
            rowButton(
                title: "Weight",
                systemImage: "number",
                value: weightPrimaryText,
                isPlaceholder: weightPrimaryText == "Set"
            ) {
                isEditWeightPresented = true
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private var genderPickerSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            pickerSheetHeader(
                title: "Choose gender",
                subtitle: "This helps tune your calorie and macro estimates.",
                dismiss: { showGenderSheet = false }
            )
            genderOption(.male, emoji: "👨", subtitle: "Use male-based macro equations.", tint: .fuelBlue)
            genderOption(.female, emoji: "👩", subtitle: "Use female-based macro equations.", tint: .pink)
            genderOption(.preferNotToSay, emoji: "✨", subtitle: "Keep things private and balanced.", tint: .fuelOrange)
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(Color(.systemGroupedBackground))
    }

    private func genderOption(_ option: Gender, emoji: String, subtitle: String, tint: Color) -> some View {
        Button {
            draft.gender = option
            showGenderSheet = false
        } label: {
            HStack(spacing: 14) {
                Text(emoji)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(tint.opacity(colorScheme == .dark ? 0.22 : 0.12), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.displayName)
                        .font(.headline.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(draft.gender == option ? tint : Color.gray.opacity(0.24), lineWidth: draft.gender == option ? 2 : 1))
        }
        .buttonStyle(.plain)
    }

    private var targetsCard: some View {
        VStack(spacing: 10) {
            rowButton(title: "Goal", systemImage: "scope", value: goalTitle, isPlaceholder: draft.goalType == nil) {
                showGoalSheet = true
            }
            Divider()
            rowButton(title: "Non-training Activity", systemImage: "figure.walk", value: activityLevelTitle, isPlaceholder: draft.nonTrainingActivityLevel == nil) {
                showActivitySheet = true
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private var goalPickerSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            pickerSheetHeader(
                title: "Choose your goal",
                subtitle: "This shapes your macro targets and goal fit score.",
                dismiss: { showGoalSheet = false }
            )
            ForEach(GoalType.allCases, id: \.self) { goal in
                goalOptionRow(goal)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(Color(.systemGroupedBackground))
    }

    private func goalOptionRow(_ goal: GoalType) -> some View {
        Button {
            draft.goalType = goal
            showGoalSheet = false
        } label: {
            HStack(alignment: .top, spacing: 14) {
                goalSymbol(goal)
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.displayName)
                        .font(.headline.weight(.semibold))
                    Text(goal.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(draft.goalType == goal ? Color.fuelOrange : Color.gray.opacity(0.24), lineWidth: draft.goalType == goal ? 2 : 1))
        }
        .buttonStyle(.plain)
    }

    private func goalSymbol(_ goal: GoalType) -> some View {
        Image(systemName: goal.symbolName)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color.primary)
            .frame(width: 44, height: 44)
            .background(Color(.systemBackground), in: Circle())
            .overlay {
                Circle()
                    .stroke(Color.fuelOrange.opacity(colorScheme == .dark ? 0.24 : 0.16), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 8, y: 4)
    }

    private func pickerSheetHeader(title: String, subtitle: String, dismiss: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private func pickerOptionContent(isSelected: Bool, title: String, detail: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.subheadline)
                .foregroundStyle(isSelected ? tint : Color.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var activityPickerSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            pickerSheetHeader(
                title: "Daily movement",
                subtitle: "Outside workouts, how active is your normal day?",
                dismiss: { showActivitySheet = false }
            )

            ForEach(NonTrainingActivityLevel.allCases, id: \.self) { level in
                activityOptionRow(level)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(Color(.systemGroupedBackground))
    }

    private func activityOptionRow(_ level: NonTrainingActivityLevel) -> some View {
        Button {
            draft.nonTrainingActivityLevel = level
            showActivitySheet = false
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Text(activityEmoji(for: level))
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(Color.fuelBlue.opacity(colorScheme == .dark ? 0.22 : 0.12), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(.headline.weight(.semibold))
                    Text(level.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(draft.nonTrainingActivityLevel == level ? Color.fuelBlue : Color.gray.opacity(0.24), lineWidth: draft.nonTrainingActivityLevel == level ? 2 : 1))
        }
        .buttonStyle(.plain)
    }

    private func activityEmoji(for level: NonTrainingActivityLevel) -> String {
        switch level {
        case .mostlySitting: return "🪑"
        case .somewhatActive: return "🏃"
        case .physicallyDemanding: return "🏗️"
        }
    }

    private var initials: String {
        let trimmed = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "GF" }
        let parts = trimmed.split(separator: " ")
        if let first = parts.first, let last = parts.last, first != last {
            return "\(first.prefix(1))\(last.prefix(1))".uppercased()
        }
        return String(trimmed.prefix(2)).uppercased()
    }

    private func sectionHeader(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 2)
    }

    private func rowLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.fuelBlue.opacity(colorScheme == .dark ? 0.2 : 0.12))
                    .frame(width: 30, height: 30)

                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.fuelBlue)
            }
            Text(title)
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private func rowButton(
        title: String,
        systemImage: String,
        value: String,
        isPlaceholder: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                rowLabel(title, systemImage: systemImage)
                Spacer()
                Text(value)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(isPlaceholder ? .secondary : .primary)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 8)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }


    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.primary.opacity(0.06), lineWidth: 1)
            )
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.08),
                radius: colorScheme == .dark ? 14 : 10,
                x: 0,
                y: colorScheme == .dark ? 8 : 6
            )
    }
}


