//
//  RootTabView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import SwiftUI

struct RootView: View {
    
    @EnvironmentObject private var authManager: FirebaseAuthManager
    @EnvironmentObject private var profileViewModel: UserProfileViewModel
    @EnvironmentObject private var subscriptionViewModel: SubscriptionViewModel
    @EnvironmentObject private var healthWeightSync: HealthWeightSyncService
    @StateObject private var savedMealsViewModel = SavedMealsViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var didEnterBackground = false
    @State private var showPostOnboardingPaywall = false
    @State private var isFinishingOnboarding = false
    @State private var pendingOnboarding: OnboardingAnswers?
    @State private var guestOnboardingActive = false
    @State private var showSaveProgress = false
    @State private var guestAuthOutcome: AuthAccountOutcome?
    @State private var guestCompletionReady = false
    @State private var guestCompletionNeedsPaywall = false

    private var onboardingSaveFailed: Binding<Bool> {
        Binding(
            get: {
                pendingOnboarding != nil
                    && !isFinishingOnboarding
                    && profileViewModel.errorMessage != nil
            },
            set: { presented in
                if !presented { profileViewModel.errorMessage = nil }
            }
        )
    }

    /// Pulls anything new out of Apple Health and reflects the newest weight in
    /// memory, so the weight shown is current without waiting for a profile
    /// refetch. No-ops entirely unless the user has connected Health.
    @MainActor
    private func importHealthWeight(for uid: String) async {
        if let kg = await healthWeightSync.syncIfConnected(userId: uid) {
            profileViewModel.applyWeighIn(kg: kg)
        }
    }

    @MainActor
    private func saveOnboarding(_ answers: OnboardingAnswers) {
        guard let uid = authManager.user?.uid else { return }

        let namedAnswers = answersWithAccountName(answers)
        pendingOnboarding = namedAnswers
        isFinishingOnboarding = true

        Task {
            await profileViewModel.completeOnboarding(for: uid, answers: namedAnswers)

            isFinishingOnboarding = false

            if profileViewModel.profile?.isOnboardingComplete == true {
                pendingOnboarding = nil

                // The uid was already in hand, so `.task(id:)` will not re-fire
                // and nothing else would import until the next foreground. The
                // guest path gets this from `finishGuestOnboarding`.
                await importHealthWeight(for: uid)

                if !subscriptionViewModel.hasProAccess {
                    FirebaseTelemetryService.logOnboardingEvent("paywall_presented")
                    showPostOnboardingPaywall = true
                }
            }
        }
    }

    private func answersWithAccountName(_ answers: OnboardingAnswers) -> OnboardingAnswers {
        var named = answers
        let existingName = profileViewModel.profile?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let providerName = authManager.user?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        named.name = existingName.isEmpty ? providerName : existingName
        return named
    }

    @MainActor
    private func authenticatedAfterGuestOnboarding(_ outcome: AuthAccountOutcome) {
        guard guestOnboardingActive, pendingOnboarding != nil else { return }
        guestAuthOutcome = outcome
        finishGuestOnboarding()
    }

    private func finishGuestPresentation() {
        guard guestCompletionReady else { return }
        guestCompletionReady = false
        pendingOnboarding = nil
        guestAuthOutcome = nil
        guestOnboardingActive = false

        if guestCompletionNeedsPaywall {
            guestCompletionNeedsPaywall = false
            FirebaseTelemetryService.logOnboardingEvent("paywall_presented")
            showPostOnboardingPaywall = true
        }
    }

    @MainActor
    private func finishGuestOnboarding() {
        guard !isFinishingOnboarding,
              let outcome = guestAuthOutcome,
              authManager.user?.uid == outcome.uid else { return }

        isFinishingOnboarding = true
        Task {
            let uid = outcome.uid
            await profileViewModel.loadProfile(for: uid)

            guard let profile = profileViewModel.profile, profile.id == uid else {
                isFinishingOnboarding = false
                return
            }

            var completedNewOnboarding = false
            if outcome.isNewUser && !profile.isOnboardingComplete {
                guard let answers = pendingOnboarding else {
                    profileViewModel.errorMessage = "Your plan is no longer available. Please start onboarding again."
                    isFinishingOnboarding = false
                    return
                }
                let namedAnswers = answersWithAccountName(answers)
                pendingOnboarding = namedAnswers
                await profileViewModel.completeOnboarding(for: uid, answers: namedAnswers)
                guard profileViewModel.profile?.isOnboardingComplete == true else {
                    isFinishingOnboarding = false
                    return
                }
                completedNewOnboarding = true
            }

            await subscriptionViewModel.syncUser(userId: uid)
            await savedMealsViewModel.loadSavedMeals(userId: uid)
            await importHealthWeight(for: uid)

            isFinishingOnboarding = false
            guestCompletionNeedsPaywall = completedNewOnboarding && !subscriptionViewModel.hasProAccess
            guestCompletionReady = true
            let wasPresented = showSaveProgress
            showSaveProgress = false
            if !wasPresented { finishGuestPresentation() }
        }
    }

    var body: some View {
        Group {
                if guestOnboardingActive {
                    OnboardingFlowView(
                        onExit: authManager.user == nil ? {
                            pendingOnboarding = nil
                            guestOnboardingActive = false
                        } : nil
                    ) { answers in
                        pendingOnboarding = answers
                        showSaveProgress = true
                    }
                    .fullScreenCover(isPresented: $showSaveProgress, onDismiss: finishGuestPresentation) {
                        PostOnboardingAuthView(
                            isFinishing: isFinishingOnboarding,
                            accountIsNew: guestAuthOutcome?.isNewUser,
                            errorMessage: profileViewModel.errorMessage,
                            onBack: { showSaveProgress = false },
                            onRetry: finishGuestOnboarding,
                            onAuthenticated: authenticatedAfterGuestOnboarding
                        )
                        .interactiveDismissDisabled(isFinishingOnboarding)
                    }
                } else if authManager.user == nil {
                    AuthFlowView(onGetStarted: { guestOnboardingActive = true })
                }  else if let profile = profileViewModel.profile {
                    if profile.isOnboardingComplete {
                        MainTabView(profile: profile)
                            .environmentObject(savedMealsViewModel)
                    } else {
                        OnboardingFlowView { answers in
                            saveOnboarding(answers)
                        }
                        .overlay {
                            if isFinishingOnboarding {
                                AppLoadingView()
                                    .ignoresSafeArea()
                                    .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: isFinishingOnboarding)
                        .alert(
                            "We couldn't finish setting up your profile",
                            isPresented: onboardingSaveFailed
                        ) {
                            Button("Try Again") {
                                if let pending = pendingOnboarding { saveOnboarding(pending) }
                            }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text(profileViewModel.errorMessage ?? "Please try again.")
                        }
                    }
                } else if profileViewModel.isLoading {
                    AppLoadingView()
                } else {
                    AppLoadingView()
                }
        }
        .sheet(isPresented: $showPostOnboardingPaywall) {
            SubscriptionPaywallSheet()
        }
        .task(id: authManager.user?.uid) {
            if let user = authManager.user {
                if guestOnboardingActive { return }
                await subscriptionViewModel.syncUser(userId: user.uid)
                await profileViewModel.loadProfile(for: user.uid)
                await savedMealsViewModel.loadSavedMeals(userId: user.uid)
                await importHealthWeight(for: user.uid)
            } else {
                await subscriptionViewModel.syncUser(userId: nil)
                profileViewModel.clear()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                didEnterBackground = true
            case .active:
                guard didEnterBackground else { return }
                didEnterBackground = false

                guard let uid = authManager.user?.uid else { return }

                // A scale that synced overnight should be on the trend before
                // the user looks at it. Ahead of the subscription guard below
                // on purpose: an in-flight purchase must not swallow the import.
                Task { await importHealthWeight(for: uid) }

                guard !subscriptionViewModel.isSyncingStatus,
                      !subscriptionViewModel.isPurchasing,
                      !subscriptionViewModel.isRestoring else { return }

                Task {
                    await subscriptionViewModel.refreshCustomerInfo()
                }
            default:
                break
            }
        }
    }
    
   
}

#Preview {
    RootView()
        .environmentObject(FirebaseAuthManager())
        .environmentObject(UserProfileViewModel())
        .environmentObject(SubscriptionViewModel())
        .environmentObject(SavedMealsViewModel())
        .environmentObject(HealthWeightSyncService())
}
