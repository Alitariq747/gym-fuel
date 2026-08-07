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
    @StateObject private var savedMealsViewModel = SavedMealsViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var didEnterBackground = false
 
        
    
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
                            Task {
                                guard let uid = authManager.user?.uid else { return }
                                await profileViewModel.completeOnboarding(for: uid, name: name, gender: gender, heightCm: heightCm, age: age, weightKg: weightKg, goalType: goalType, nonTrainingActivityLevel: nonTrainingActivityLevel)
                            }
                        }
                    }
                } else if profileViewModel.isLoading {
                    AppLoadingView()
                } else {
                    AppLoadingView()
                }
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
