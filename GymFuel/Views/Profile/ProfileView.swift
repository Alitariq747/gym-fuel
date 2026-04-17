//
//  ProfileView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/01/2026.
//

import SwiftUI
import AuthenticationServices

struct ProfileView: View {
    @EnvironmentObject private var profileVm: UserProfileViewModel
    @EnvironmentObject private var authManager: FirebaseAuthManager
    @EnvironmentObject private var savedMealsViewModel: SavedMealsViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var draft: UserProfileDraft? = nil
    @State private var signOutError: String?
    @State private var isSigningOut: Bool = false
    @State private var isDeletingAccount: Bool = false
    @State private var showDeleteAccountConfirmation: Bool = false
    @State private var showEmailReauthPrompt: Bool = false
    @State private var showAppleReauthSheet: Bool = false
    @State private var showSavedMealsSheet: Bool = false
    @State private var deleteEmail: String = ""
    @State private var deletePassword: String = ""
    @State private var deleteAppleNonce: String?
    @State private var showSaveToast: Bool = false

    private let privacyURL = URL(string: "https://alitariq747.github.io/lifteats-legal/privacy-policy")
    private let termsURL = URL(string: "https://alitariq747.github.io/lifteats-legal/terms")

    private var isBusy: Bool {
        profileVm.isSaving || isSigningOut || isDeletingAccount
    }

    private var draftBinding: Binding<UserProfileDraft>? {
        guard draft != nil else { return nil }

        return Binding(
            get: {
                if let draft = self.draft {
                    return draft
                }

                // The binding is only exposed when draft exists, so this fallback
                // should never be reached in practice.
                return UserProfileDraft(from: self.profileVm.profile ?? dummyProfile)
            },
            set: { self.draft = $0 }
        )
    }
    
    var body: some View {
        ZStack {
            Group {
                if isSigningOut || isDeletingAccount {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(isDeletingAccount ? "Deleting account…" : "Signing out…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else if profileVm.profile != nil {
                    if let draftBinding {
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

                                                if profileVm.errorMessage == nil {
                                                    showSaveToast = true
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                        showSaveToast = false
                                                        dismiss()
                                                    }
                                                }
                                            }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "checkmark")
                                                    .font(.footnote.weight(.bold))
                                                Text("Save")
                                                    .font(.subheadline.weight(.semibold))
                                            }
                                            .foregroundStyle(canSave && !isBusy ? .primary : .secondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(
                                                Color(.systemBackground),
                                                in: Capsule()
                                            )
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

                                savedMealsSection
                                legalSection
                                  
                                
                                if let signOutError {
                                    Text(signOutError)
                                        .font(.footnote)
                                        .foregroundStyle(.red)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal)
                                }
                                
                                accountSection
                                    .padding(.bottom)
                            }
                        }
                        .scrollDismissesKeyboard(.interactively)
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
        .overlay(alignment: .bottom) {
            if showSaveToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.fuelGreen)
                    Text("Profile updated")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                )
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSaveToast)
        .task(id: profileVm.profile?.id) {
            if let profile = profileVm.profile {
                draft = UserProfileDraft(from: profile)
            } else {
                draft = nil
            }
        }
        .confirmationDialog("Delete Account?", isPresented: $showDeleteAccountConfirmation, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) {
                Task { await startDeleteFlow() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all associated data from LiftEats. This action cannot be undone.")
        }
        .alert("Confirm your password", isPresented: $showEmailReauthPrompt) {
            TextField("Email", text: $deleteEmail)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            SecureField("Password", text: $deletePassword)
            Button("Cancel", role: .cancel) {
                deletePassword = ""
                signOutError = verificationCancelledMessage
            }
            Button("Continue", role: .destructive) {
                Task { await reauthenticateWithEmailAndDelete() }
            }
        } message: {
            Text("For security, re-enter your email and password before deleting your account.")
        }
        .sheet(isPresented: $showAppleReauthSheet) {
            appleReauthSheet
        }
        .sheet(isPresented: $showSavedMealsSheet) {
            SavedMealsSheet()
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
        if draft.goalType != profile.goalType { return true }
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
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemBackground).opacity(colorScheme == .dark ? 0.75 : 0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
            )
        }
        .padding(.horizontal)
        .opacity(0.92)
    }

    private var savedMealsSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "Saved Meals", systemImage: "bookmark")
            Button {
                showSavedMealsSheet = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.fuelBlue.opacity(0.12))
                            .frame(width: 52, height: 52)

                        Image(systemName: "fork.knife")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.fuelBlue)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Manage Saved Meals")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(savedMealsViewModel.savedMeals.count)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 4)
                }
                .contentShape(Rectangle())
                .padding(16)
            }
            .buttonStyle(.plain)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.fuelBlue.opacity(0.12), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }

    private var accountSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "Account", systemImage: "person.crop.circle")
            VStack(spacing: 0) {
                Button(role: .destructive) {
                    Task { await handleSignOut() }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 18)

                        Text(isSigningOut ? "Signing out…" : "Sign out")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.primary)

                        Spacer()

                        if isSigningOut {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .disabled(isBusy)

                Divider()

                Button(role: .destructive) {
                    showDeleteAccountConfirmation = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "trash.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                            .frame(width: 18)

                        Text("Delete Account")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.red)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.red.opacity(0.6))
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .disabled(isBusy)
            }
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.red.opacity(0.14), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }

    private func linkRow(title: String, systemImage: String, url: URL?) -> some View {
        let rowContent = HStack {
            rowLabel(title, systemImage: systemImage)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.leading, 6)
        }
        .contentShape(Rectangle())

        return Group {
            if let url {
                Link(destination: url) {
                    rowContent
                }
            } else {
                rowContent
            }
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

    private var appleReauthSheet: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("Verify with Apple")
                    .font(.headline)

                Text("To delete your account, confirm your Apple sign-in first.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                SignInWithAppleButton(.continue) { request in
                    let nonce = authManager.generateNonce()
                    deleteAppleNonce = nonce
                    request.requestedScopes = []
                    request.nonce = authManager.sha256(nonce)
                } onCompletion: { result in
                    Task { await handleAppleReauthForDelete(result) }
                }
                .frame(height: 48)

                Button("Cancel", role: .cancel) {
                    showAppleReauthSheet = false
                    signOutError = verificationCancelledMessage
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    @MainActor
    private func handleSignOut() async {
        guard !isSigningOut else { return }
        signOutError = nil
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

    @MainActor
    private func startDeleteFlow() async {
        guard let user = authManager.user else {
            signOutError = AuthManagerError.invalidCredential.localizedDescription
            return
        }

        signOutError = nil
        deleteEmail = user.email ?? ""
        deletePassword = ""

        let providerIDs = Set(user.providerData.map(\.providerID))

        if providerIDs.contains("password") {
            showEmailReauthPrompt = true
            return
        }

        if providerIDs.contains("google.com") {
            await reauthenticateWithGoogleAndDelete()
            return
        }

        if providerIDs.contains("apple.com") {
            deleteAppleNonce = nil
            showAppleReauthSheet = true
            return
        }

        await performDeleteAccount()
    }

    @MainActor
    private func reauthenticateWithEmailAndDelete() async {
        guard !isDeletingAccount else { return }
        signOutError = nil
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        do {
            try await authManager.reauthenticateForDeleteWithEmail(email: deleteEmail, password: deletePassword)
        } catch {
            setVerificationError(error)
            return
        }

        deletePassword = ""

        do {
            try await performDeleteAccountAfterReauth()
        } catch {
            setDeleteError(error)
        }
    }

    @MainActor
    private func reauthenticateWithGoogleAndDelete() async {
        guard !isDeletingAccount else { return }
        signOutError = nil
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        do {
            try await authManager.reauthenticateForDeleteWithGoogle()
        } catch {
            setVerificationError(error)
            return
        }

        do {
            try await performDeleteAccountAfterReauth()
        } catch {
            setDeleteError(error)
        }
    }

    @MainActor
    private func handleAppleReauthForDelete(_ result: Result<ASAuthorization, Error>) async {
        guard !isDeletingAccount else { return }
        showAppleReauthSheet = false
        signOutError = nil
        defer { deleteAppleNonce = nil }
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        do {
            let authorization = try result.get()
            guard let rawNonce = deleteAppleNonce else {
                throw AuthManagerError.unknown
            }

            try await authManager.reauthenticateForDeleteWithApple(
                authorization: authorization,
                rawNonce: rawNonce
            )
        } catch {
            setVerificationError(error)
            return
        }

        do {
            try await performDeleteAccountAfterReauth()
        } catch {
            setDeleteError(error)
        }
    }

    @MainActor
    private func performDeleteAccount() async {
        guard !isDeletingAccount else { return }
        signOutError = nil
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        do {
            try await performDeleteAccountAfterReauth()
        } catch {
            setDeleteError(error)
        }
    }

    @MainActor
    private func performDeleteAccountAfterReauth() async throws {
        try await authManager.deleteAccount()
        profileVm.clear()
        dismiss()
    }

    private var verificationCancelledMessage: String {
        "Verification cancelled. Your account was not deleted."
    }

    private func setVerificationError(_ error: Error) {
        if isCancellation(error) {
            signOutError = verificationCancelledMessage
            return
        }

        let details = (error as? AuthManagerError)?.localizedDescription ?? error.localizedDescription
        signOutError = "Verification failed. \(details)"
    }

    private func setDeleteError(_ error: Error) {
        let details = (error as? AuthManagerError)?.localizedDescription ?? error.localizedDescription
        signOutError = "Delete failed. \(details)"
    }

    private func isCancellation(_ error: Error) -> Bool {
        if let authError = error as? AuthManagerError,
           case .operationCancelled = authError {
            return true
        }

        let nsError = error as NSError
        if nsError.domain == ASAuthorizationError.errorDomain,
           let code = ASAuthorizationError.Code(rawValue: nsError.code),
           code == .canceled {
            return true
        }

        if nsError.domain.localizedCaseInsensitiveContains("gidsignin"),
           nsError.code == -5 {
            return true
        }

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
        .environmentObject(SavedMealsViewModel())
}
