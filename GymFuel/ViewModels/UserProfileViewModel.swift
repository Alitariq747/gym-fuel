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
       /// The goal-and-pace stretch in force. `nil` until `loadPhase` finishes,
       /// and targets simply read an adjustment of 0 until then.
       @Published private(set) var phase: Phase?
       /// Today's target: the formula plus the current phase's adjustment.
       var targetMacros: Macros? {
           guard let profile else { return nil }
           return macroTargetCalculator.targetMacros(
               for: profile,
               calorieAdjustment: phase?.calorieAdjustment ?? 0
           )
       }

       private let service: FirebaseUserProfileService
       private let macroTargetCalculator: MacroTargetCalculator
       private let weighInService: WeighInService
       private let phaseService: PhaseService
       private let phasePlanner: PhasePlanner

       init(
           service: FirebaseUserProfileService = .shared,
           macroTargetCalculator: MacroTargetCalculator = MacroTargetCalculator(),
           weighInService: WeighInService = FirebaseWeighInService(),
           phaseService: PhaseService = FirebasePhaseService(),
           phasePlanner: PhasePlanner = PhasePlanner()
       ) {
           self.service = service
           self.macroTargetCalculator = macroTargetCalculator
           self.weighInService = weighInService
           self.phaseService = phaseService
           self.phasePlanner = phasePlanner
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
            await loadPhase(for: uid)
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

    /// Reads the current phase, then starts or updates one if the profile no
    /// longer matches it.
    ///
    /// Separate from `loadProfile` so it never holds up the first screen. Runs
    /// again after every profile save, reading fresh rather than trusting memory:
    /// planning against a phase that simply hadn't loaded yet would start a new
    /// one and drop the carried adjustment.
    ///
    /// **Never sets `errorMessage`.** `RootView`'s onboarding failure alert reads
    /// it, and a phase write failing must not tell someone their profile failed.
    /// Failures are non-fatals; the next launch retries.
    func loadPhase(for uid: String, now: Date = .now) async {
        let fetch: PhaseFetch
        do {
            fetch = try await phaseService.fetchCurrentPhase(for: uid)
        } catch {
            FirebaseTelemetryService.recordNonFatal(error, reason: "phase_load_failed", metadata: [:])
            return
        }

        phase = fetch.phase

        // Only a server read can prove a phase is missing or stale. An empty
        // offline cache would otherwise start a fresh phase at adjustment 0.
        guard fetch.isFromServer,
              let profile,
              profile.isOnboardingComplete
        else { return }

        let plan = phasePlanner.plan(
            profile: profile,
            current: fetch.phase,
            todayKey: DateKey.key(for: now),
            now: now
        )

        do {
            switch plan {
            case .keep:
                break
            case .start(let newPhase):
                try await phaseService.startPhase(newPhase, for: uid)
                phase = newPhase
            case .updateTargetWeight(let targetWeightKg):
                guard let current = fetch.phase else { return }
                try await phaseService.updateTargetWeight(
                    targetWeightKg,
                    phaseKey: current.startDateKey,
                    for: uid
                )
                phase?.targetWeightKg = targetWeightKg
            }
        } catch {
            FirebaseTelemetryService.recordNonFatal(error, reason: "phase_sync_failed", metadata: [:])
        }
    }

    /// Puts the cached phase in memory before the profile arrives, so the first
    /// screen already shows the check-in's adjustment instead of jumping when
    /// `loadPhase` finishes.
    ///
    /// Cache only: no network wait, and offline it is the same data `loadPhase`
    /// would find. Never plans or writes — an empty cache proves nothing.
    func loadCachedPhase(for uid: String) async {
        guard phase == nil, let cached = await phaseService.fetchCachedPhase(for: uid) else { return }
        // `loadPhase` may have answered while the cache read was in flight.
        guard phase == nil else { return }
        phase = cached
    }

    /// Reflects a check-in answer in memory so `targetMacros` moves at once. The
    /// durable write is the check-in's own batch, not this.
    func applyCheckInDecision(_ update: PhaseDecisionUpdate) {
        guard phase?.startDateKey == update.phaseKey else { return }
        if let calorieAdjustment = update.calorieAdjustment {
            phase?.calorieAdjustment = calorieAdjustment
        }
        phase?.lastStepDecisionDateKey = update.decisionDateKey
    }

    func clear() {
        profile = nil
        phase = nil
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
            await loadPhase(for: uid)
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
