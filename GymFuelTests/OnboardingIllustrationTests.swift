//
//  OnboardingIllustrationTests.swift
//  GymFuelTests
//

import Testing

@testable import LiftEats

@Suite("Onboarding illustration")
struct OnboardingIllustrationTests {
    @Test("The two busiest steps show only the small plate face")
    func busyStepsShowTheFace() {
        #expect(OnboardingStep.loggingTips.illustration == .face)
        #expect(OnboardingStep.summary.illustration == .face)
    }

    @Test("Every other step shows a moving plate")
    func otherStepsMove() {
        let busy: Set<OnboardingStep> = [.loggingTips, .summary]
        for step in OnboardingStep.allCases where !busy.contains(step) {
            #expect(step.illustration != .face, "\(step)")
        }
    }
}
