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
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var draft: UserProfile? = nil
    @State private var signOutError: String?
    @State private var isSigningOut: Bool = false
    @State private var showSignOutConfirmation: Bool = false
    @State private var isDeletingAccount: Bool = false
    @State private var showDeleteAccountConfirmation: Bool = false
    @State private var showEmailReauthPrompt: Bool = false
    @State private var showAppleReauthSheet: Bool = false
    @State private var showSavedMealsSheet: Bool = false
    @State private var showNutritionSourcesSheet: Bool = false
    @State private var showTargetsSheet: Bool = false
    @State private var showWeightScreen: Bool = false
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

    private var draftBinding: Binding<UserProfile>? {
        guard draft != nil else { return nil }

        return Binding(
            get: {
                if let draft = self.draft {
                    return draft
                }

                // The binding is only exposed when draft exists, so this fallback
                // should never be reached in practice.
                return self.profileVm.profile ?? UserProfile(
                    id: "", name: "", heightCm: nil, age: nil, weightKg: nil,
                    goalType: nil, activityLevel: nil,
                    isOnboardingComplete: false, gender: .preferNotToSay
                )
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
                            .font(.circaCaption)
                            .foregroundStyle(Color.circaInk2)
                    }
                } else if profileVm.profile != nil {
                    if let draftBinding {
                        ScrollView {
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        CircaSectionLabel("Your journal")
                                        Spacer()
                                        Button {
                                            dismiss()
                                        } label: {
                                            Image(systemName: "xmark")
                                                .foregroundStyle(Color.circaInk)
                                                .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                                                .background(Color.circaCard, in: Circle())
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Close Settings")
                                        .disabled(isBusy)
                                    }

                                    Text("Settings")
                                        .font(.circaTitle)
                                        .foregroundStyle(Color.circaInk)

                                    if profileVm.isSaving {
                                        ProgressView("Saving changes…")
                                    } else if canSave {
                                        Button {
                                            Task {
                                                guard let uid = authManager.user?.uid else { return }
                                                guard let draft else { return }

                                                await profileVm.saveProfileEdits(for: uid, draft: draft)

                                                if let updated = profileVm.profile {
                                                    self.draft = updated
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
                                            Label("Save changes", systemImage: "checkmark")
                                                .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.circa(.primary))
                                        .disabled(isBusy)
                                    }
                                }
                                .padding(.horizontal, Circa.Space.screenMargin)
                                .padding(.top, 18)

                                ProfileEditorView(
                                    draft: draftBinding,
                                    email: authManager.user?.email,
                                    onOpenTargets: { showTargetsSheet = true },
                                    onOpenWeight: { showWeightScreen = true }
                                )
                                    .disabled(isBusy)
                                    .opacity(isBusy ? 0.6 : 1)

                                ProfileAppearanceSection(colorSchemePreference: $colorSchemePreference)
                                ProfileReminderSection(preferredColorScheme: preferredColorScheme)
                                ProfileHealthSection(
                                    userId: profileVm.profile?.id ?? "",
                                    onWeightImported: { kg in
                                        profileVm.applyWeighIn(kg: kg)
                                        // The draft is seeded once per uid, so
                                        // an import landing while this screen is
                                        // open would otherwise leave a stale
                                        // weight in it — and `saveProfileEdits`
                                        // writes the whole draft, which would
                                        // put the old weight back.
                                        draft?.weightKg = kg
                                    }
                                )
                                ProfileSubscriptionSection(
                                    status: subscriptionViewModel.status,
                                    isSyncingStatus: subscriptionViewModel.isSyncingStatus,
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
                                ProfileLiftEatsSection(reviewURL: appStoreReviewURL)
                                ProfileLegalSection(
                                    privacyURL: privacyURL,
                                    termsURL: termsURL,
                                    supportURL: supportURL,
                                    onOpenNutritionSources: { showNutritionSourcesSheet = true }
                                )
                                  
                                
                                if let signOutError {
                                    Text(signOutError)
                                        .font(.circaCaption)
                                        .foregroundStyle(Color.circaDanger)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, Circa.Space.screenMargin)
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
                        .font(.circaBody)
                        .foregroundStyle(Color.circaDanger)
                } else {
                    ProgressView("Preparing your profile…")
                }
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .circaPaper()
        .overlay(alignment: .bottom) {
            if showSaveToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaAccent)
                    Text("Profile updated")
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaInk)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.circaCard, in: Capsule())
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSaveToast)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showWeightScreen) {
            WeightView()
                .toolbar(.visible, for: .navigationBar)
        }
        .onChange(of: showWeightScreen) { _, isPresented in
            if !isPresented { adoptTargetsScreenChanges() }
        }
        .task(id: profileVm.profile?.id) {
            if let profile = profileVm.profile {
                draft = profile
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
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSignOutConfirmation) {
            signOutConfirmationSheet
                .preferredColorScheme(preferredColorScheme)
                .presentationDetents([.medium, .large])
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
        .sheet(isPresented: $showTargetsSheet, onDismiss: adoptTargetsScreenChanges) {
            TargetsView()
                .preferredColorScheme(preferredColorScheme)
        }
        .sheet(isPresented: $showNutritionSourcesSheet) {
            NutritionSourcesView(primaryButtonTitle: "Done")
                .preferredColorScheme(preferredColorScheme)
        }
    }

    @MainActor
    private func openManageSubscriptions() async {
        guard let windowScene = activeWindowScene() else {
            openURL(appStoreSubscriptionsURL)
            return
        }

        do {
            try await AppStore.showManageSubscriptions(in: windowScene)
        } catch {
            openURL(appStoreSubscriptionsURL)
            return
        }

        Task {
            await subscriptionViewModel.refreshCustomerInfo()
        }
    }

    @MainActor
    private func activeWindowScene() -> UIWindowScene? {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return windowScenes.first(where: { $0.activationState == .foregroundActive }) ?? windowScenes.first
    }

    private var deleteAccountWarningSheet: some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 20) {
                CircaSectionLabel("Account")
                Text("Delete your account?")
                    .font(.circaTitle)
                    .foregroundStyle(Color.circaInk)

                CircaCard(.danger) {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.circaTitle)
                            .foregroundStyle(Color.circaDanger)
                            .accessibilityHidden(true)
                        Text("This permanently removes your Circa account, profile, saved meals, and logged history. This action cannot be undone.")
                            .font(.circaBody)
                            .foregroundStyle(Color.circaInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text("Deleting your Circa account does not cancel an Apple subscription. Manage or cancel your subscription through Apple before deleting your account.")
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)

                Button(role: .destructive) {
                    showDeleteAccountConfirmation = false
                    Task { await startDeleteFlow() }
                } label: {
                    Text("Delete Account")
                        .font(.circaRow)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .foregroundStyle(Color.circaDanger)
                        .background(Color.circaDangerGround, in: RoundedRectangle(cornerRadius: Circa.Radius.button))
                        .overlay {
                            RoundedRectangle(cornerRadius: Circa.Radius.button)
                                .strokeBorder(Color.circaDangerBorder, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)

                Button("Cancel") {
                    showDeleteAccountConfirmation = false
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.circa(.quiet))
            }
            .padding(Circa.Space.screenMargin)
        }
        .circaPaper()
    }

    private var signOutConfirmationSheet: some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 20) {
                CircaSectionLabel("Account")
                Text("Sign out of Circa?")
                    .font(.circaTitle)
                    .foregroundStyle(Color.circaInk)

                Text("You can sign back in anytime. Your saved profile and logs will remain available.")
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)

                Button(role: .destructive) {
                    showSignOutConfirmation = false
                    Task { await handleSignOut() }
                } label: {
                    Text("Sign Out")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary, height: 52))

                Button("Cancel") {
                    showSignOutConfirmation = false
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.circa(.quiet))
            }
            .padding(Circa.Space.screenMargin)
        }
        .circaPaper()
    }

    /// The targets screen saves through the view model, so this draft is stale the
    /// moment it does — and Save here writes the whole draft. Re-seed it from the
    /// saved profile, keeping the fields this screen itself owns.
    private func adoptTargetsScreenChanges() {
        guard let saved = profileVm.profile, let edited = draft else { return }

        var merged = saved
        merged.adoptSettingsEdits(from: edited)
        draft = merged
    }

    private var canSave: Bool {
        guard let profile = profileVm.profile, let draft else { return false }
        guard SafetyLimits.ageProblem(draft.age) == nil else { return false }

        return isDirty(draft: draft, profile: profile) && !profileVm.isSaving
    }

    private func isDirty(draft: UserProfile, profile: UserProfile) -> Bool {

        if draft.name.trimmingCharacters(in: .whitespacesAndNewlines) != profile.name { return true }
        if draft.gender != profile.gender { return true }
        if draft.age != profile.age { return true }
        if draft.heightCm != profile.heightCm { return true }
        // Weight is deliberately absent: this screen displays it but cannot edit
        // it, so it can never be the reason there are changes to save. Goal and
        // daily activity left for the same reason in Step 4d — changing either has
        // to recalculate the targets and restart the plan line, which is the
        // targets screen's job, not this draft's.
        return false
    }

    private var accountSection: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "Account")
            VStack(spacing: 0) {
                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.circaRow)
                            .frame(width: 30)

                        Text(isSigningOut ? "Signing out…" : "Sign out")
                            .font(.circaRow)

                        Spacer()

                        if isSigningOut {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.circaCaption)
                        }
                    }
                    .foregroundStyle(Color.circaInk)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 14)
                    .frame(minHeight: 56)
                }
                .buttonStyle(.plain)
                .disabled(isBusy)

                CircaHairline(weight: .inCard)

                Button(role: .destructive) {
                    showDeleteAccountConfirmation = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "trash.fill")
                            .font(.circaRow)
                            .frame(width: 30)

                        Text("Delete Account")
                            .font(.circaRow)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.circaCaption)
                    }
                    .foregroundStyle(Color.circaDanger)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 14)
                    .frame(minHeight: 56)
                }
                .buttonStyle(.plain)
                .disabled(isBusy)
            }
            .background(ProfileCardBackground())
        }
        .padding(.horizontal, Circa.Space.screenMargin)
    }

    private var appleReauthSheet: some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 20) {
                CircaSectionLabel("Account security")
                Text("Verify with Apple")
                    .font(.circaTitle)
                    .foregroundStyle(Color.circaInk)

                Text("To delete your account, confirm your Apple sign-in first.")
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)

                SignInWithAppleButton(.continue) { request in
                    let nonce = authManager.generateNonce()
                    deleteAppleNonce = nonce
                    request.requestedScopes = []
                    request.nonce = authManager.sha256(nonce)
                } onCompletion: { result in
                    Task { await handleAppleReauthForDelete(result) }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .id(colorScheme)

                Button("Cancel", role: .cancel) {
                    showAppleReauthSheet = false
                    signOutError = verificationCancelledMessage
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.circa(.quiet))
            }
            .padding(Circa.Space.screenMargin)
        }
        .circaPaper()
        .presentationDetents([.medium, .large])
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
