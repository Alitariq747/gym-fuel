//
//  ProfileEditorView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 29/01/2026.
//

import SwiftUI

struct ProfileEditorView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var draft: UserProfileDraft
    let email: String?

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
    @State private var showGenderDialog = false

    private var genderTitle: String {
        draft.gender.displayName
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
        VStack(alignment: .leading, spacing: 18) {
            profileHeader

            VStack(spacing: 12) {
                sectionHeader(title: "Body Metrics", systemImage: "figure.stand")
                bodyMetricsCard
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
            .presentationDetents([.large])
        }
        .sheet(isPresented: $isEditWeightPresented) {
            NavigationStack {
                EditWeightSheet(weightKg: $draft.weightKg)
            }
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
                showGenderDialog = true
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
                systemImage: "scalemass",
                value: weightPrimaryText,
                isPlaceholder: weightPrimaryText == "Set"
            ) {
                isEditWeightPresented = true
            }
        }
        .padding(14)
        .background(cardBackground)
        .confirmationDialog("Pick Gender", isPresented: $showGenderDialog, titleVisibility: .visible) {
            Button("\(Gender.male.symbol) \(Gender.male.displayName)") { draft.gender = .male }
            Button("\(Gender.female.symbol) \(Gender.female.displayName)") { draft.gender = .female }
            Button(Gender.preferNotToSay.displayName) { draft.gender = .preferNotToSay }
            Button("Cancel", role: .cancel) {}
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

#Preview {
        ProfileEditorPreviewWrapper()
    
}

private struct ProfileEditorPreviewWrapper: View {
    @State private var draft = UserProfileDraft.preview

    var body: some View {
        ProfileEditorView(draft: $draft, email: "ahmad@example.com")
    }
}
