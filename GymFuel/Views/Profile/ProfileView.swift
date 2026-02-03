//
//  ProfileView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/01/2026.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var profileVm: UserProfileViewModel
    @EnvironmentObject private var authManager: FirebaseAuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var draft: UserProfileDraft? = nil
    
    var body: some View {
        ZStack {
             AppBackground()

            Group {
                if profileVm.profile != nil {
                    if let draftBinding = Binding($draft) {
                        VStack(spacing: 16) {
                            HStack {
                                if profileVm.isSaving {
                                    ProgressView()
                                } else {
                                    Button {
                                        Task {
                                            guard let uid = authManager.user?.uid else { return }
                                            guard let draft else { return }
                                            
                                            await profileVm.saveProfileEdits(for: uid, draft: draft)
                                            
                                            if let updated = profileVm.profile {
                                                self.draft = UserProfileDraft(from: updated)
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "checkmark")
                                            .font(.headline)
                                            .foregroundStyle(.secondary)
                                            .padding(10)
                                            .background(Color(.systemBackground), in: Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!canSave)
                                }
                                Spacer()
                                Text("Settings")
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity)
                                Spacer()
                                Button {
                                    dismiss()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                        .padding(10)
                                        .background(Color(.systemBackground), in: Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal)
                            .padding(.top)

                            ProfileEditorView(draft: draftBinding, email: authManager.user?.email)
                        }
                    } else {
                        ProgressView("Getting Editor")
                    }
                } else if profileVm.isLoading {
                    ProgressView("Loading Profile")
                } else {
                    Text(profileVm.errorMessage ?? "No profile available")
                        .padding()
                        .font(.subheadline)
                        .foregroundStyle(.red.opacity(0.7))
                }
            }

        }
        .task(id: profileVm.profile?.id) {
            if let profile = profileVm.profile {
                draft = UserProfileDraft(from: profile)
            } else {
                draft = nil
            }
        }
    }
    private var canSave: Bool {
        guard let profile = profileVm.profile, let draft else { return false }

        let trimmed = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        return isDirty(draft: draft, profile: profile) && !profileVm.isSaving
    }

    private func isDirty(draft: UserProfileDraft, profile: UserProfile) -> Bool {

        if draft.name.trimmingCharacters(in: .whitespacesAndNewlines) != profile.name { return true }
        if draft.gender != profile.gender { return true }
        if draft.age != profile.age { return true }
        if draft.heightCm != profile.heightCm { return true }
        if draft.weightKg != profile.weightKg { return true }
        if draft.trainingGoal != profile.trainingGoal { return true }
        if draft.trainingDaysPerWeek != profile.trainingDaysPerWeek { return true }
        if draft.trainingExperience != profile.trainingExperience { return true }
        if draft.trainingStyle != profile.trainingStyle { return true }
        if draft.trainingTimeOfDay != profile.trainingTimeOfDay { return true }
        if draft.nonTrainingActivityLevel != profile.nonTrainingActivityLevel { return true }
        return false
    }

    
}

#Preview {
    let auth = FirebaseAuthManager()
    let profileVM = UserProfileViewModel()
    profileVM._setProfileForPreview(dummyProfile)

    return ProfileView()
        .environmentObject(auth)
        .environmentObject(profileVM)
}


