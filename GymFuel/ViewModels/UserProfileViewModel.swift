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
       private let weighInService: WeighInService

       init(
           service: FirebaseUserProfileService = .shared,
           macroTargetCalculator: MacroTargetCalculator = MacroTargetCalculator(),
           weighInService: WeighInService = FirebaseWeighInService()
       ) {
           self.service = service
           self.macroTargetCalculator = macroTargetCalculator
           self.weighInService = weighInService
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
            await seedFirstWeighIn(for: uid, weightKg: profile.weightKg)
        } catch {
            FirebaseTelemetryService.logOnboardingEvent("complete_failed")
            self.errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't finish setting up your profile. Please try again."
            )
        }
        isLoading = false
    }
    
    /// Reflects a weigh-in in memory so `targetMacros` recomputes immediately and
    /// `ProfileView.isDirty` does not report unsaved changes for a value that is
    /// already saved. The durable write is the weigh-in's own, not this.
    func applyWeighIn(kg: Double) {
        profile?.weightKg = kg
    }

    /// Records the onboarding weight as day zero of the trend.
    ///
    /// Without it a user needs two weigh-ins before the chart shows anything —
    /// at weekly cadence, week three. With it, their first weigh-in draws a line.
    /// The seed is self-reported and so weaker than a real weigh-in, but at
    /// alpha 0.25 a half-kilo of seed error is largely gone within three
    /// readings.
    ///
    /// Deliberately best-effort: onboarding has already succeeded by this point,
    /// and failing it over a seed row would be worse than starting the chart a
    /// week late.
    private func seedFirstWeighIn(for uid: String, weightKg: Double?) async {
        guard let weightKg, weightKg > 0 else { return }

        let weighIn = WeighIn(weightKg: BodyWeight.roundedForStorage(weightKg), source: .manual)

        do {
            try await weighInService.saveWeighIn(weighIn, for: uid)
        } catch {
            FirebaseTelemetryService.recordNonFatal(
                error,
                reason: "onboarding_weigh_in_seed_failed",
                metadata: ["dateKey": weighIn.dateKey]
            )
        }
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
