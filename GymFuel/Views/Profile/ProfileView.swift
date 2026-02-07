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
    @State private var signOutError: String?
    @State private var isSigningOut: Bool = false
    
    var body: some View {
        let isBusy = profileVm.isSaving || isSigningOut
        let isSignedOut = authManager.user == nil
        ZStack {
             AppBackground()

            Group {
                if isSigningOut || isSignedOut {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Signing out…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else if profileVm.profile != nil {
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
                                    .disabled(!canSave || isBusy)
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
                                .disabled(isBusy)
                            }
                            .padding(.horizontal)
                            .padding(.top)

                            ProfileEditorView(draft: draftBinding, email: authManager.user?.email)
                                .disabled(isBusy)
                                .opacity(isBusy ? 0.6 : 1)
                            
                            if let signOutError {
                                Text(signOutError)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                            }
                            
                            Button(role: .destructive) {
                                Task { await handleSignOut() }
                            } label: {
                                HStack(spacing: 10) {
                                    if isSigningOut {
                                        ProgressView()
                                            .controlSize(.small)
                                    }

                                    Text(isSigningOut ? "Signing out…" : "Sign out")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .disabled(isBusy)
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    } else {
                        ProgressView("Getting Editor")
                    }
                } else if profileVm.isLoading {
                    ProgressView("Loading Profile")
                } else if let message = profileVm.errorMessage {
                    Text(message)
                        .padding()
                        .font(.subheadline)
                        .foregroundStyle(.red.opacity(0.7))
                } else {
                    ProgressView("Preparing your profile…")
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

    @MainActor
    private func handleSignOut() async {
        guard !isSigningOut else { return }
        isSigningOut = true
        defer { isSigningOut = false }

        do {
            profileVm.clear()
            try authManager.signOut()
            signOutError = nil
            dismiss()
        } catch {
            signOutError = (error as? AuthManagerError)?.localizedDescription ?? error.localizedDescription
        }
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
