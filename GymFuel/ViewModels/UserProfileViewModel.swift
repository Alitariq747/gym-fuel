//
//  UserProfileViewModel.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import Foundation

import SwiftUI

@MainActor
final class UserProfileViewModel: ObservableObject {
    
       @Published private(set) var profile: UserProfile?
       @Published private(set) var isLoading: Bool = false
       @Published var errorMessage: String?
       @Published private(set) var isSaving: Bool = false
       var targetMacros: Macros? {
           guard let profile else { return nil }
           return macroTargetCalculator.targetMacros(for: profile)
       }
       
       private let service: FirebaseUserProfileService
       private let macroTargetCalculator: MacroTargetCalculator
       
       init(
           service: FirebaseUserProfileService = .shared,
           macroTargetCalculator: MacroTargetCalculator = MacroTargetCalculator()
       ) {
           self.service = service
           self.macroTargetCalculator = macroTargetCalculator
       }
    
    func loadProfile(for uid: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let profile = try await service.fetchProfile(for: uid)
            self.profile = profile
        } catch {
            self.errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't load your profile. Please try again."
            )
            self.profile = nil
        }
        isLoading = false
    }
    
    func completeOnboarding(for uid: String, answers: OnboardingAnswers) async {

        isLoading = true
        errorMessage = nil

        guard let profile = answers.toProfile(id: uid) else {
            FirebaseTelemetryService.logOnboardingEvent("complete_failed")
            self.errorMessage = "We couldn't finish setting up your profile. Please try again."
            isLoading = false
            return
        }

        do {
            let updatedProfile = try await service.updateProfile(profile)
            self.profile = updatedProfile
            FirebaseTelemetryService.logOnboardingEvent("complete_succeeded")
        } catch {
            FirebaseTelemetryService.logOnboardingEvent("complete_failed")
            self.errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't finish setting up your profile. Please try again."
            )
        }
        isLoading = false
    }
    
    func clear() {
        profile = nil
        isLoading = false
        errorMessage = nil
    }
    
    func saveProfileEdits(for uid: String, draft: UserProfile) async {
        isSaving = true
        defer { isSaving = false }
        errorMessage = nil

        do {
            guard let currentProfile = self.profile else { return }

            var profile = draft
            profile.id = uid
            profile.isOnboardingComplete = currentProfile.isOnboardingComplete

            let updatedProfile = try await service.updateProfile(profile)

            self.profile = updatedProfile
        } catch {
            self.errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't save your profile changes. Please try again."
            )
        }
    }
    
    
}

#if DEBUG
extension UserProfileViewModel {
    func _setProfileForPreview(_ profile: UserProfile) {
        self.profile = profile
        self.isLoading = false
        self.errorMessage = nil
    }
}
#endif
