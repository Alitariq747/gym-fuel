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
       /// The saved targets — read, never recalculated, so a weigh-in cannot move them.
       var targetMacros: Macros? {
           profile?.savedTargets
       }
       
       private let service: FirebaseUserProfileService
       private let macroTargetCalculator: MacroTargetCalculator
       private let weighInService: WeighInService
       private let networkMonitor: NetworkMonitoring

       init(
           service: FirebaseUserProfileService = .shared,
           macroTargetCalculator: MacroTargetCalculator = MacroTargetCalculator(),
           weighInService: WeighInService = FirebaseWeighInService(),
           networkMonitor: NetworkMonitoring = NetworkMonitor.shared
       ) {
           self.service = service
           self.macroTargetCalculator = macroTargetCalculator
           self.weighInService = weighInService
           self.networkMonitor = networkMonitor
       }
    
    func loadProfile(for uid: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let profile = try await service.fetchProfile(for: uid)
            self.profile = profile
            saveMissingTargets(profile)
        } catch {
            self.errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't load your profile. Please try again."
            )
            self.profile = nil
        }
        isLoading = false
    }
    
    /// Accounts that finished onboarding before targets were saved get them
    /// worked out and saved once. Only test accounts are in that state.
    ///
    /// The write is not awaited: offline it never gets a server reply, and the
    /// launch must not wait on it. If it fails, the next launch tries again.
    private func saveMissingTargets(_ loaded: UserProfile) {
        guard loaded.isOnboardingComplete,
              loaded.savedTargets == nil,
              let targets = macroTargetCalculator.targets(for: loaded) else { return }

        var profile = loaded
        let now = Date.now
        profile.setTargets(targets, on: now)
        if profile.planStartedOn == nil {
            profile.startPlan(on: now)
        }
        self.profile = profile

        Task {
            do {
                _ = try await service.updateProfile(profile)
            } catch {
                FirebaseTelemetryService.recordNonFatal(error, reason: "profile_targets_backfill_failed")
            }
        }
    }

    func completeOnboarding(for uid: String, answers: OnboardingAnswers) async {

        isLoading = true
        errorMessage = nil

        // Worked out once and saved, with any edit made on the plan screen. From
        // now on only the user changes them.
        guard let profile = answers.plannedProfile(id: uid, on: .now, using: macroTargetCalculator) else {
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
    
    /// Reflects a weigh-in in memory so the weight shown is current and
    /// `ProfileView.isDirty` does not report unsaved changes for a value that is
    /// already saved. The durable write is the weigh-in's own, not this. The
    /// saved targets stay as they are: a weigh-in never changes them.
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

    // MARK: - Targets the user changes

    /// Saves numbers the user typed, with carbs filled and the floors held by
    /// `MacroTargetCalculator.edited` before they arrive here.
    ///
    /// Stamps "Set at" with today and the current weight, keeps the maintenance
    /// estimate as it was — the formula's estimate is not a target — and **leaves
    /// the plan line alone**: editing targets does not redraw it
    /// (`build-order.md` Step 4, *The rules*).
    func saveEditedTargets(_ macros: Macros) async {
        guard let current = profile,
              let maintenance = current.maintenanceCalories
                ?? macroTargetCalculator.targets(for: current)?.maintenanceCalories
        else { return }

        var updated = current
        updated.setTargets(MacroTargets(macros: macros, maintenanceCalories: maintenance), on: .now)

        await writeTargets(updated)
    }

    /// Fresh numbers from the latest weigh-in, and the plan line restarted from
    /// today — one re-anchoring gesture, decided 19 September.
    ///
    /// `weightKg` is only ever written by a weigh-in, so it *is* the latest one and
    /// this recalculates from the weight the screen is showing. No extra read.
    func recalculateTargets() async {
        guard let current = profile,
              let targets = macroTargetCalculator.targets(for: current) else { return }

        let now = Date.now
        var updated = current
        updated.setTargets(targets, on: now)
        updated.startPlan(on: now)

        await writeTargets(updated)
    }

    /// The one path for a change to the goal, the goal weight or the activity
    /// level. Each of them changes the numbers and where the plan line starts, so
    /// each recalculates and restarts it — *The rules*.
    func updatePlan(_ change: UserProfile.PlanChange) async {
        guard let current = profile else { return }

        var updated = current
        guard updated.applyPlanChange(change, on: .now, using: macroTargetCalculator) else {
            errorMessage = "We couldn't work out new targets for that. Please check your age, height and weight."
            return
        }

        await writeTargets(updated)
    }

    /// The one write all three paths use.
    ///
    /// Memory is updated only after the write succeeds, so a failed save never
    /// leaves the app showing numbers Firestore does not have.
    private func writeTargets(_ updated: UserProfile) async {
        // `ProfileView.draftBinding`'s fallback builds a profile with an empty id;
        // writing that would create `users//…`.
        guard !updated.id.isEmpty else {
            errorMessage = "We couldn't tell which account to save this to. Please try again."
            return
        }
        errorMessage = nil

        // Same reason as `saveProfileEdits`: awaiting a write with no network never
        // resumes, which would leave this screen's buttons dead and its numbers
        // stale while the change sat unseen in the local cache.
        guard networkMonitor.isConnected else {
            do {
                try service.updateTargetsLocally(for: updated)
                profile = updated
            } catch {
                errorMessage = AppErrorMessage.message(
                    for: error,
                    fallback: "We couldn't save your targets. Please try again."
                )
            }
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await service.updateTargets(for: updated)
            profile = updated
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't save your targets. Please try again."
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

            // Firestore acknowledges a write only from the server, so awaiting one
            // with no network never resumes and the Save button would spin for ever.
            // Queue it into the local cache instead and let it sync.
            if networkMonitor.isConnected {
                self.profile = try await service.updateProfile(profile)
            } else {
                self.profile = try service.updateProfileLocally(profile)
            }
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
