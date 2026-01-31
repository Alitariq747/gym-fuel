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
    private let genderOptions: [(value: String, title: String, symbol: String)] = [
        ("male", "Male", "♂"),
        ("female", "Female", "♀")
    ]

    private var genderTitle: String {
        switch draft.gender {
        case "male": return "Male"
        case "female": return "Female"
        default: return "Select"
        }
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
    
    // Training Goal
    @State private var isEditGoalPresented = false
    private var trainingGoalPrimaryText: String {
        draft.trainingGoal?.displayName ?? "Set"
    }
    
    // Training Style
    @State private var isEditTrainingStylePresented = false

    // Training time
    @State private var isEditTrainingTimePresented = false
    
    private var trainingTimePrimaryText: String {
        draft.trainingTimeOfDay?.displayName ?? "Set"
    }

    // Training Experience
    @State private var isEditTrainingExperiencePresented = false


    
    var body: some View {
        ScrollView {
            // Parent VStack
            VStack(alignment: .leading, spacing: 20) {
                // VStack for name and email
                VStack {
                    // HStack for name
                    HStack(alignment: .center) {
                        Text("Name")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("Name", text: $draft.name)
                        .font(.callout)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .foregroundStyle(.primary)
                    }
                    Divider()
                    HStack(alignment: .center) {
                        Text("Email")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(email ?? "-")
                            .font(.callout)
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(.systemBackground), lineWidth: 1))
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.08), radius: colorScheme == .dark ? 18 : 12, x: 0, y: colorScheme == .dark ? 10 : 6)
                
                // VStack for our Body Metrcis i.e gender, weight, height, age
                VStack(spacing: 14) {
                    Text("Body Metrics")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 10) {
                        // age hStack
                        HStack(alignment: .center) {
                            Text("Age")
                                .font(.callout)
                                .foregroundStyle(.secondary)

                            Spacer()

                            TextField("—", text: $ageText)
                                .font(.callout)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numberPad)
                                .onChange(of: ageText) { _, newValue in
                                    applyAgeTextToDraft(newValue)
                                }
                            EmptyView()
                        }
                        // Gender HStack
                        Divider()
                        Button {
                            showGenderDialog = true
                        } label: {
                            HStack(alignment: .center) {
                                Text("Gender")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text(genderTitle)
                                    .font(.callout)
                                    .foregroundStyle(.primary)
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                                    .padding(.leading, 6)
                            }
                        }
                        .buttonStyle(.plain)
                        .confirmationDialog("Pick Gender", isPresented: $showGenderDialog, titleVisibility: .visible) {
                            Button("♂ Male") { draft.gender = "male" }
                             Button("♀ Female") { draft.gender = "female" }
                             Button("Cancel", role: .cancel) {}
                        }
                        Divider()
                        // Height Row
                        Button {
                            isEditHeightPresented = true
                        } label: {
                            HStack {
                                Text("Height")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                    Text(heightPrimaryText)
                                        .font(.callout)
                                        .foregroundStyle(.primary)


                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                                    .padding(.leading, 6)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                        // Weight row
                        Button {
                                isEditWeightPresented = true
                            } label: {
                                HStack {
                                    Text("Weight")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                        Text(weightPrimaryText)
                                            .font(.callout)
                                            .foregroundStyle(.primary)

                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                        .padding(.leading, 6)
                                }
                            }
                            .buttonStyle(.plain)
                        
                        
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(.systemBackground), lineWidth: 1))
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.08), radius: colorScheme == .dark ? 18 : 12, x: 0, y: colorScheme == .dark ? 10 : 6)
                }
                
                // VStack for training related fields
                VStack(spacing: 14) {
                    Text("Training")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 10) {
                        // Training Goal
                        Button {
                                isEditGoalPresented = true
                            } label: {
                                HStack {
                                    Text("Training Goal")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    Text(trainingGoalPrimaryText.truncated(to: 15, addEllipsis: true))
                                            .font(.callout)
                                            .foregroundStyle(.primary)

                                    
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                        .padding(.leading, 6)
                                }
                            }
                            .buttonStyle(.plain)
                        Divider()
                        
                        // Training Style
                        Button {
                            isEditTrainingStylePresented = true
                        } label: {
                            HStack {
                                Text("Training Style")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text(draft.trainingStyle?.displayName.truncated(to: 15, addEllipsis: true) ?? "Set")
                                        .font(.callout)
                                        .foregroundStyle(.primary)

                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                                    .padding(.leading, 6)
                            }
                        }
                        .buttonStyle(.plain)
                        Divider()
                        
                        // Training Time
                        Button {
                                isEditTrainingTimePresented = true
                            } label: {
                                HStack {
                                    Text("Training Time")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                        Text(trainingTimePrimaryText)
                                            .font(.callout)
                                            .foregroundStyle(.primary)


                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                        .padding(.leading, 6)
                                }
                            }
                            .buttonStyle(.plain)
                        Divider()
                        // Training experience
                        Button {
                                isEditTrainingExperiencePresented = true
                            } label: {
                                HStack {
                                    Text("Training Experience")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    Text(draft.trainingExperience?.displayName.truncated(to: 15, addEllipsis: true) ?? "Set")
                                            .font(.callout)
                                            .foregroundStyle(.primary)

 

                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                        .padding(.leading, 6)
                                }
                            }
                            .buttonStyle(.plain)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(.systemBackground), lineWidth: 1))
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.08), radius: colorScheme == .dark ? 18 : 12, x: 0, y: colorScheme == .dark ? 10 : 6)
                }
            }
            .padding()

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
        .sheet(isPresented: $isEditGoalPresented) {
            NavigationStack {
                EditTrainingGoalSheet(trainingGoal: $draft.trainingGoal)
            }
        }
        .sheet(isPresented: $isEditTrainingStylePresented) {
            NavigationStack {
                EditTrainingStyleSheet(trainingStyle: $draft.trainingStyle)
            }
        }
        .sheet(isPresented: $isEditTrainingTimePresented) {
            NavigationStack {
                EditTrainingTimeSheet(trainingTime: $draft.trainingTimeOfDay)
            }
        }
        .sheet(isPresented: $isEditTrainingExperiencePresented) {
            NavigationStack {
                EditTrainingExperienceSheet(trainingExperience: $draft.trainingExperience)
            }
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        ProfileEditorPreviewWrapper()
    }
}

private struct ProfileEditorPreviewWrapper: View {
    @State private var draft = UserProfileDraft.preview

    var body: some View {
        ProfileEditorView(draft: $draft, email: "ahmad@example.com")
    }
}


