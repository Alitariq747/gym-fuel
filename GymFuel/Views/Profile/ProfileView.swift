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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var draft: UserProfileDraft? = nil
    @State private var signOutError: String?
    @State private var isSigningOut: Bool = false

    private let privacyURL = URL(string: "https://alitariq747.github.io/lifteats-legal/privacy-policy")!
    private let termsURL = URL(string: "https://alitariq747.github.io/lifteats-legal/terms")!
    
    var body: some View {
        let isBusy = profileVm.isSaving || isSigningOut
        let isSignedOut = authManager.user == nil
        ZStack {
             AppBackground()

            Group {
                if isSigningOut {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Signing out…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else if profileVm.profile != nil {
                    if let draftBinding = Binding($draft) {
                        ScrollView {
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

                                legalSection
                                
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

    private var legalSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "Legal", systemImage: "doc.text")
            VStack(spacing: 10) {
                linkRow(title: "Privacy Policy", systemImage: "hand.raised.fill", url: privacyURL)
                Divider()
                linkRow(title: "Terms of Service", systemImage: "checkmark.seal.fill", url: termsURL)
            }
            .padding(14)
            .background(cardBackground)
        }
        .padding(.horizontal)
    }

    private func linkRow(title: String, systemImage: String, url: URL) -> some View {
        Link(destination: url) {
            HStack {
                rowLabel(title, systemImage: systemImage)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 6)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.fuelBlue)
                .frame(width: 18)
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
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
