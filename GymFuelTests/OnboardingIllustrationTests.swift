//
//  OnboardingIllustrationTests.swift
//  GymFuelTests
//

import Testing

@testable import LiftEats

@Suite("Onboarding illustration")
struct OnboardingIllustrationTests {
    @Test("The two teaching screens show no illustration")
    func teachingStepsShowNothing() {
        #expect(OnboardingStep.liftEatsIntro.illustration == .hidden)
        #expect(OnboardingStep.liftEatsDifference.illustration == .hidden)
    }

    @Test("The two busiest steps show only the small plate face")
    func busyStepsShowTheFace() {
        #expect(OnboardingStep.loggingTips.illustration == .face)
        #expect(OnboardingStep.summary.illustration == .face)
    }

    @Test("The gender step's move is wonder")
    func genderStepWonders() {
        #expect(OnboardingStep.gender.illustration == .plate(.wonder))
    }

    @Test("Every other step shows a moving plate")
    func otherStepsMove() {
        let exempt: Set<OnboardingStep> = [
            .liftEatsIntro, .liftEatsDifference, .loggingTips, .summary
        ]
        for step in OnboardingStep.allCases where !exempt.contains(step) {
            #expect(isPlate(step.illustration), "\(step)")
        }
    }

    private func isPlate(_ illustration: OnboardingIllustration) -> Bool {
        if case .plate = illustration { return true }
        return false
    }
}
