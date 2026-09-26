//
//  ProfileEditorView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 29/01/2026.
//

import SwiftUI

struct ProfileEditorView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @AppStorage("appColorSchemePreference") private var colorSchemePreference = "system"
    @Binding var draft: UserProfile
    let email: String?
    /// Opens the targets screen (Step 4d). `ProfileView` presents it, because the
    /// screen saves through the profile view model rather than through this draft.
    let onOpenTargets: () -> Void
    let onOpenWeight: () -> Void

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
        // Kept exactly as typed. `SafetyLimits.ageProblem` explains an age that
        // cannot be used, and `ProfileView.canSave` stops it being saved.
        draft.age = Int(digits)
    }
    
    // gender
    @State private var showGenderSheet = false

    private var genderTitle: String {
        draft.gender.displayName
    }

    /// The saved calorie target, read and never recalculated here.
    private var targetsTitle: String {
        guard let calories = draft.savedTargets?.calories else { return "View" }
        return "\(Int(calories.rounded())) kcal"
    }

    // Height
    @State private var isEditHeightPresented = false

    private var heightPrimaryText: String {
        guard let cm = draft.heightCm, cm > 0 else { return "Set" }
        return "\(Int(cm.rounded())) cm"
    }
    
    // Weight — displayed, never edited here. See `bodyMetricsCard`.
    /// Shared with the weigh-in sheet, so a pounds user reads pounds here too.
    @AppStorage(BodyWeightUnit.preferenceKey) private var unitRawValue = BodyWeightUnit.kilograms.rawValue

    private var weightPrimaryText: String {
        guard let kg = draft.weightKg, kg > 0 else { return "—" }
        return BodyWeight.displayString(kilograms: kg, unit: BodyWeightUnit(rawValue: unitRawValue) ?? .kilograms)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            profileHeader

            VStack(spacing: 12) {
                ProfileSectionHeader(title: "Body Metrics")
                bodyMetricsCard
            }

            VStack(spacing: 12) {
                ProfileSectionHeader(title: "Targets")
                targetsCard
            }
        }
        .padding(.horizontal, Circa.Space.screenMargin)
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
        .sheet(isPresented: $showGenderSheet) {
            genderPickerSheet
                .preferredColorScheme(preferredColorScheme)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.circaSunken)
                        .frame(width: 52, height: 52)
                    if initials.isEmpty {
                        Image(systemName: "person.fill")
                            .font(.circaRow)
                            .foregroundStyle(Color.circaInk2)
                            .accessibilityHidden(true)
                    } else {
                        Text(initials)
                            .font(.circaMonoValue)
                            .foregroundStyle(Color.circaInk)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    TextField("Your name", text: $draft.name)
                        .font(.circaEntryTitle)
                        .foregroundStyle(Color.circaInk)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                    Text(email ?? "—")
                        .font(.circaMono)
                        .foregroundStyle(Color.circaInk2)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ProfileCardBackground())
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
            if let problem = SafetyLimits.ageProblem(draft.age) {
                Text(problem)
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaDanger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            CircaHairline(weight: .inCard)
            rowButton(
                title: "Gender",
                systemImage: "person.fill",
                value: genderTitle,
                isPlaceholder: false
            ) {
                showGenderSheet = true
            }
            CircaHairline(weight: .inCard)
            rowButton(
                title: "Height",
                systemImage: "ruler",
                value: heightPrimaryText,
                isPlaceholder: heightPrimaryText == "Set"
            ) {
                isEditHeightPresented = true
            }
            CircaHairline(weight: .inCard)
            // Weight is still read from weigh-ins; this row opens their history.
            rowButton(
                title: "Weight",
                systemImage: "scalemass",
                value: weightPrimaryText,
                isPlaceholder: weightPrimaryText == "—",
                action: onOpenWeight
            )
        }
        .padding(14)
        .background(ProfileCardBackground())
    }

    private var genderPickerSheet: some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        CircaSectionLabel("About you")
                        Text("What's your gender?")
                            .font(.circaTitle)
                            .foregroundStyle(Color.circaInk)
                        Text("This helps us calculate better calorie and macro goals.")
                            .font(.circaBody)
                            .foregroundStyle(Color.circaInk2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Button {
                        showGenderSheet = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.circaRow)
                            .foregroundStyle(Color.circaInk2)
                            .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                            .background(Color.circaSunken, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                VStack(spacing: 12) {
                    genderOption(.male)
                    genderOption(.female)
                    genderOption(.preferNotToSay)
                }
            }
            .padding(Circa.Space.screenMargin)
        }
        .circaPaper()
    }

    private func genderOption(_ option: Gender) -> some View {
        let isSelected = draft.gender == option
        return Button {
            draft.gender = option
            showGenderSheet = false
        } label: {
            HStack(spacing: 12) {
                Image(systemName: option.iconName)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Color.circaInk2)
                    .frame(width: 26)
                    .accessibilityHidden(true)

                Text(option.displayName)
                    .font(.circaEntryTitle)
                    .foregroundStyle(Color.circaInk)
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.circaAccent : Color.circaInk3)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: Circa.minHitTarget)
            .background(Color.circaCard, in: RoundedRectangle(cornerRadius: Circa.Radius.cardSmall))
            .overlay {
                RoundedRectangle(cornerRadius: Circa.Radius.cardSmall)
                    .strokeBorder(isSelected ? Color.circaAccent : Color.circaCardBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private var targetsCard: some View {
        VStack(spacing: 10) {
            rowButton(
                title: "Your targets",
                systemImage: "list.bullet.rectangle",
                value: targetsTitle,
                isPlaceholder: draft.savedTargets == nil,
                action: onOpenTargets
            )
        }
        .padding(14)
        .background(ProfileCardBackground())
    }

    private var initials: String {
        let trimmed = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let parts = trimmed.split(separator: " ")
        if let first = parts.first, let last = parts.last, first != last {
            return "\(first.prefix(1))\(last.prefix(1))".uppercased()
        }
        return String(trimmed.prefix(2)).uppercased()
    }

    private func rowLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.circaRow)
                .foregroundStyle(Color.circaInk2)
                .frame(width: 30, height: 30)
                .background(Color.circaWell, in: RoundedRectangle(cornerRadius: Circa.Radius.thumb))
                .accessibilityHidden(true)
            Text(title)
                .font(.circaRow)
                .foregroundStyle(Color.circaInk)
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
            Group {
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 8) {
                        rowLabel(title, systemImage: systemImage)
                        rowValue(value, isPlaceholder: isPlaceholder)
                    }
                } else {
                    HStack {
                        rowLabel(title, systemImage: systemImage)
                        Spacer(minLength: 8)
                        rowValue(value, isPlaceholder: isPlaceholder)
                    }
                }
            }
            .frame(minHeight: Circa.minHitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func rowValue(_ value: String, isPlaceholder: Bool) -> some View {
        HStack {
            Text(value)
                .font(.circaMono)
                .foregroundStyle(isPlaceholder ? Color.circaInk3 : Color.circaInk2)
            Image(systemName: "chevron.right")
                .font(.circaCaption)
                .foregroundStyle(Color.circaInk3)
                .padding(.leading, 8)
                .accessibilityHidden(true)
        }
    }
}
