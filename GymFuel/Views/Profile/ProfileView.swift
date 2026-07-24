//
//  ProfileView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/01/2026.
//

import SwiftUI
import AuthenticationServices
import StoreKit
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var profileVm: UserProfileViewModel
    @EnvironmentObject private var authManager: FirebaseAuthManager
    @EnvironmentObject private var savedMealsViewModel: SavedMealsViewModel
    @EnvironmentObject private var subscriptionViewModel: SubscriptionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    @State private var draft: UserProfileDraft? = nil
    @State private var signOutError: String?
    @State private var isSigningOut: Bool = false
    @State private var showSignOutConfirmation: Bool = false
    @State private var isDeletingAccount: Bool = false
    @State private var showDeleteAccountConfirmation: Bool = false
    @State private var showEmailReauthPrompt: Bool = false
    @State private var showAppleReauthSheet: Bool = false
    @State private var showSavedMealsSheet: Bool = false
    @State private var showGoalFitExplainerSheet: Bool = false
    @State private var showSubscriptionPaywall: Bool = false
    @State private var deleteEmail: String = ""
    @State private var deletePassword: String = ""
    @State private var deleteAppleNonce: String?
    @State private var showSaveToast: Bool = false
    @AppStorage("appColorSchemePreference") private var colorSchemePreference = AppColorSchemePreference.system.rawValue

    private let privacyURL = URL(string: "https://ahmadtariq.co/apps/lifteats/privacy")
    private let termsURL = URL(string: "https://ahmadtariq.co/apps/lifteats/terms")
    private let supportURL = URL(string: "mailto:support-lifteats@ahmadtariq.co")
    private let appStoreReviewURL = URL(string: "https://apps.apple.com/app/id6778838787?action=write-review")!
    private let appStoreSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    private var isBusy: Bool {
        profileVm.isSaving || isSigningOut || isDeletingAccount
    }

    private var preferredColorScheme: ColorScheme? {
        AppColorSchemePreference(rawValue: colorSchemePreference)?.colorScheme
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
                                ZStack {
                                    Text("Settings")
                                        .font(.title2.weight(.semibold))
                                        .foregroundStyle(.primary)

                                    HStack {
                                        Group {
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
                                                            .font(.caption.weight(.bold))
                                                        Text("Save")
                                                            .font(.caption.weight(.bold))
                                                    }
                                                    .foregroundStyle(canSave && !isBusy ? .primary : .secondary)
                                                    .frame(height: 32)
                                                    .padding(.horizontal, 12)
                                                    .background(Color(.secondarySystemBackground), in: Capsule())
                                                    .overlay(Capsule().stroke(Color.black.opacity(0.05), lineWidth: 1))
                                                }
                                                .buttonStyle(.plain)
                                                .shadow(color: .black.opacity(canSave && !isBusy ? 0.06 : 0), radius: 8, y: 3)
                                                .disabled(!canSave || isBusy)
                                            }
                                        }
                                        .frame(width: 72, alignment: .leading)

                                        Spacer()

                                        Button {
                                            dismiss()
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.primary)
                                                .frame(width: 32, height: 32)
                                                .background(Color(.secondarySystemBackground), in: Circle())
                                                .overlay(Circle().stroke(Color.black.opacity(0.05), lineWidth: 1))
                                        }
                                        .buttonStyle(.plain)
                                        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                                        .disabled(isBusy)
                                        .frame(width: 72, alignment: .trailing)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top)

                                ProfileEditorView(draft: draftBinding, email: authManager.user?.email)
                                    .disabled(isBusy)
                                    .opacity(isBusy ? 0.6 : 1)

                                ProfileAppearanceSection(colorSchemePreference: $colorSchemePreference)
                                ProfileReminderSection(preferredColorScheme: preferredColorScheme)
                                ProfileSubscriptionSection(
                                    status: subscriptionViewModel.status,
                                    isLoading: subscriptionViewModel.isLoading,
                                    onOpenPaywall: {
                                        subscriptionViewModel.clearError()
                                        showSubscriptionPaywall = true
                                    },
                                    onManageSubscription: {
                                        subscriptionViewModel.clearError()
                                        Task {
                                            await openManageSubscriptions()
                                        }
                                    }
                                )
                                ProfileSavedMealsSection(
                                    savedMealCount: savedMealsViewModel.savedMeals.count,
                                    onOpen: { showSavedMealsSheet = true }
                                )
                                ProfileLiftEatsSection(
                                    onOpenScoreExplanation: { showGoalFitExplainerSheet = true },
                                    reviewURL: appStoreReviewURL
                                )
                                ProfileLegalSection(
                                    privacyURL: privacyURL,
                                    termsURL: termsURL,
                                    supportURL: supportURL
                                )
                                  
                                
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
        .toolbar(.hidden, for: .navigationBar)
        .task(id: profileVm.profile?.id) {
            if let profile = profileVm.profile {
                draft = UserProfileDraft(from: profile)
            } else {
                draft = nil
            }
        }
        .task {
            await subscriptionViewModel.refreshCustomerInfo()
        }
        .sheet(isPresented: $showSubscriptionPaywall, onDismiss: {
            Task {
                await subscriptionViewModel.refreshCustomerInfo()
            }
        }) {
            SubscriptionPaywallSheet()
                .preferredColorScheme(preferredColorScheme)
        }
        .sheet(isPresented: $showDeleteAccountConfirmation) {
            deleteAccountWarningSheet
                .preferredColorScheme(preferredColorScheme)
                .presentationDetents([.height(390)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSignOutConfirmation) {
            signOutConfirmationSheet
                .preferredColorScheme(preferredColorScheme)
                .presentationDetents([.height(310)])
                .presentationDragIndicator(.visible)
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
                .preferredColorScheme(preferredColorScheme)
        }
        .sheet(isPresented: $showSavedMealsSheet) {
            SavedMealsSheet()
                .preferredColorScheme(preferredColorScheme)
        }
        .sheet(isPresented: $showGoalFitExplainerSheet) {
            GoalFitScoreExplainerSheet(primaryButtonTitle: "Done")
                .preferredColorScheme(preferredColorScheme)
        }
    }

    @MainActor
    private func openManageSubscriptions() async {
        defer {
            Task {
                await subscriptionViewModel.refreshCustomerInfo()
            }
        }

        guard let windowScene = activeWindowScene() else {
            openURL(appStoreSubscriptionsURL)
            return
        }

        do {
            try await AppStore.showManageSubscriptions(in: windowScene)
        } catch {
            openURL(appStoreSubscriptionsURL)
        }
    }

    @MainActor
    private func activeWindowScene() -> UIWindowScene? {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return windowScenes.first(where: { $0.activationState == .foregroundActive }) ?? windowScenes.first
    }

    private var deleteAccountWarningSheet: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(Color.fuelRed)
                .frame(width: 74, height: 74)
                .background(Color.fuelRed.opacity(0.12), in: Circle())

            VStack(spacing: 8) {
                Text("Delete your account?")
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("This permanently removes your LiftEats account, profile, saved meals, and logged history. This action cannot be undone.\n\nDeleting your LiftEats account does not cancel an Apple subscription. Manage or cancel your subscription through Apple before deleting your account.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                Button(role: .destructive) {
                    showDeleteAccountConfirmation = false
                    Task { await startDeleteFlow() }
                } label: {
                    Text("Delete Account")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.fuelRed)

                Button("Cancel") {
                    showDeleteAccountConfirmation = false
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
            }
        }
        .padding(24)
    }

    private var signOutConfirmationSheet: some View {
        VStack(spacing: 18) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Color.fuelOrange)
                .frame(width: 68, height: 68)
                .background(Color.fuelOrange.opacity(0.12), in: Circle())

            VStack(spacing: 7) {
                Text("Sign out of LiftEats?")
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("You can sign back in anytime. Your saved profile and logs will remain available.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                Button(role: .destructive) {
                    showSignOutConfirmation = false
                    Task { await handleSignOut() }
                } label: {
                    Text("Sign Out")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.fuelRed)

                Button("Cancel") {
                    showSignOutConfirmation = false
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
            }
        }
        .padding(24)
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

    private var accountSection: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "Account", systemImage: "person.crop.circle")
            VStack(spacing: 0) {
                Button(role: .destructive) {
                    showSignOutConfirmation = true
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
            .background(ProfileCardBackground())
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.red.opacity(0.14), lineWidth: 1)
            )
        }
        .padding(.horizontal)
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
            try authManager.signOut()
            profileVm.clear()
            signOutError = nil
            dismiss()
        } catch {
            signOutError = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't sign you out. Please try again."
            )
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

        let details = AppErrorMessage.message(
            for: error,
            fallback: "Please verify your account and try again."
        )
        signOutError = "Verification failed. \(details)"
    }

    private func setDeleteError(_ error: Error) {
        let details = AppErrorMessage.message(
            for: error,
            fallback: "Please try deleting your account again."
        )
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
