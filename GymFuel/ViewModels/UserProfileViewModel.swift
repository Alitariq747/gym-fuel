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
       
       private let service: FirebaseUserProfileService
       
       init(service: FirebaseUserProfileService = .shared) {
           self.service = service
       }
    
    func loadProfile(for uid: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let profile = try await service.fetchProfile(for: uid)
            self.profile = profile
        } catch {
            self.errorMessage = error.localizedDescription
            self.profile = nil
        }
        isLoading = false
    }
    
    func completeOnboarding(for uid: String, name: String, gender: Gender, heightCm: Double, age: Int, weightKg: Double, trainingGoal: TrainingGoal, trainingDaysPerWeek: Int, trainingExperience: TrainingExperience, trainingStyle: TrainingStyle, trainingTimeOfDay: TrainingTimeOfDay, nonTrainingActivityLevel: NonTrainingActivityLevel) async {
        
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedProfile = try await service.updateProfile(for: uid, name: name, heightCm: heightCm, age: age, weightKg: weightKg, trainingGoal: trainingGoal, trainingDaysPerWeek: trainingDaysPerWeek, trainingExperience: trainingExperience, trainingStyle: trainingStyle, trainingTimeOfDay: trainingTimeOfDay, nonTrainingActivityLevel: nonTrainingActivityLevel, isOnboardingComplete: true, gender: gender)
            self.profile = updatedProfile
        } catch {
            self.errorMessage = error.localizedDescription
            self.profile = nil
        }
        isLoading = false
    }
    
    func clear() {
        profile = nil
        isLoading = false
        errorMessage = nil
    }
    
    func saveProfileEdits(for uid: String, draft: UserProfileDraft) async {
        isSaving = true
        errorMessage = nil
        
        do {
            guard let currentProfile = self.profile else { return }
            let onboarding = currentProfile.isOnboardingComplete
            
            let updatedProfile = try await service.updateProfile(for: uid, name: draft.name, heightCm: draft.heightCm, age: draft.age, weightKg: draft.weightKg, trainingGoal: draft.trainingGoal, trainingDaysPerWeek: draft.trainingDaysPerWeek, trainingExperience: draft.trainingExperience, trainingStyle: draft.trainingStyle, trainingTimeOfDay: draft.trainingTimeOfDay, nonTrainingActivityLevel: draft.nonTrainingActivityLevel, isOnboardingComplete: onboarding, gender: draft.gender)
            
            self.profile = updatedProfile
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isSaving = false
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
