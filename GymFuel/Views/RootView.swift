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
 
        
    
    var body: some View {
        Group {
            if authManager.user == nil {
                AuthView()
            }  else if let profile = profileViewModel.profile {
                if profile.isOnboardingComplete {
                    MainTabView(profile: profile)
                } else {
                    OnboardingFlowView { name, gender, age, heightCm, weightKg, trainingGoal, trainingDaysPerWeek, trainingExperience, trainingStyle, trainingTimeOfDay, nonTrainingActivityLevel in
                        Task {
                            guard let uid = authManager.user?.uid else { return }
                            await profileViewModel.completeOnboarding(for: uid, name: name, gender: gender, heightCm: heightCm, age: age, weightKg: weightKg, trainingGoal: trainingGoal, trainingDaysPerWeek: trainingDaysPerWeek, trainingExperience: trainingExperience, trainingStyle: trainingStyle, trainingTimeOfDay: trainingTimeOfDay, nonTrainingActivityLevel: nonTrainingActivityLevel)
                        }
                    }
                }
            } else if profileViewModel.isLoading {
                VStack {
                    ProgressView("Loading Profile...")
                }
            } else {
                VStack {
                    ProgressView("Preparing your account...")
                }
            }
        }
        .task(id: authManager.user?.uid) {
            if let user = authManager.user {
                await profileViewModel.loadProfile(for: user.uid)
            } else {
                 profileViewModel.clear()
            }
        }
    }
    
   
}

#Preview {
    RootView()
        .environmentObject(FirebaseAuthManager())
        .environmentObject(UserProfileViewModel())
}
