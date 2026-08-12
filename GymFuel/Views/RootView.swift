//
//  RootTabView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import SwiftUI

/// The onboarding answers held in memory while the profile save is in flight,
/// so a failed save can be retried without re-asking the user.
private struct PendingOnboarding {
    let name: String
    let gender: Gender
    let age: Int
    let heightCm: Double
    let weightKg: Double
    let goalType: GoalType
    let activityLevel: NonTrainingActivityLevel
}

struct RootView: View {
    
    @EnvironmentObject private var authManager: FirebaseAuthManager
    @EnvironmentObject private var profileViewModel: UserProfileViewModel
    @EnvironmentObject private var subscriptionViewModel: SubscriptionViewModel
    @StateObject private var savedMealsViewModel = SavedMealsViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var didEnterBackground = false
    @State private var showPostOnboardingPaywall = false
    @State private var isFinishingOnboarding = false
    @State private var pendingOnboarding: PendingOnboarding?

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

    @MainActor
    private func saveOnboarding(_ pending: PendingOnboarding) {
        guard let uid = authManager.user?.uid else { return }

        pendingOnboarding = pending
        isFinishingOnboarding = true

        Task {
            await profileViewModel.completeOnboarding(
                for: uid, name: pending.name, gender: pending.gender,
                heightCm: pending.heightCm, age: pending.age, weightKg: pending.weightKg,
                goalType: pending.goalType, nonTrainingActivityLevel: pending.activityLevel
            )

            isFinishingOnboarding = false

            if profileViewModel.profile?.isOnboardingComplete == true {
                pendingOnboarding = nil

                if !subscriptionViewModel.hasProAccess {
                    FirebaseTelemetryService.logOnboardingEvent("paywall_presented")
                    showPostOnboardingPaywall = true
                }
            }
        }
    }
 
        
    
    var body: some View {
        Group {
                if authManager.user == nil {
                    AuthFlowView()
                }  else if let profile = profileViewModel.profile {
                    if profile.isOnboardingComplete {
                        MainTabView(profile: profile)
                            .environmentObject(savedMealsViewModel)
                    } else {
                        OnboardingFlowView(
                            prefilledName: authManager.user?.displayName ?? "",
                            showsNameStep: authManager.signInProviderIDs.contains("password")
                                && (authManager.user?.displayName ?? "").isEmpty
                        ) { name, gender, age, heightCm, weightKg, goalType, nonTrainingActivityLevel in
                            saveOnboarding(
                                PendingOnboarding(
                                    name: name, gender: gender, age: age,
                                    heightCm: heightCm, weightKg: weightKg,
                                    goalType: goalType, activityLevel: nonTrainingActivityLevel
                                )
                            )
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
                await subscriptionViewModel.syncUser(userId: user.uid)
                await profileViewModel.loadProfile(for: user.uid)
                await savedMealsViewModel.loadSavedMeals(userId: user.uid)
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

                guard authManager.user != nil else { return }
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
}
