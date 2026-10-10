//
//  OnboardingIllustrationTests.swift
//  GymFuelTests
//

import Testing

@testable import Circa

@Suite("Onboarding illustration")
struct OnboardingIllustrationTests {
    @Test("The intro, the live meal, the widget step and the plan show no illustration")
    func teachingAndBusyStepsShowNothing() {
        #expect(OnboardingStep.liftEatsIntro.illustration == .hidden)
        #expect(OnboardingStep.tryMeal.illustration == .hidden)
        #expect(OnboardingStep.widget.illustration == .hidden)
        #expect(OnboardingStep.summary.illustration == .hidden)
    }

    @Test("The gender step's move is wonder")
    func genderStepWonders() {
        #expect(OnboardingStep.gender.illustration == .plate(.wonder))
    }

    @Test("The logging-problem question wonders too")
    func loggingProblemStepWonders() {
        #expect(OnboardingStep.loggingProblem.illustration == .plate(.wonder))
    }

    @Test("Every other step shows a moving plate")
    func otherStepsMove() {
        let exempt: Set<OnboardingStep> = [.liftEatsIntro, .tryMeal, .widget, .summary]
        for step in OnboardingStep.allCases where !exempt.contains(step) {
            #expect(isPlate(step.illustration), "\(step)")
        }
    }

    private func isPlate(_ illustration: OnboardingIllustration) -> Bool {
        if case .plate = illustration { return true }
        return false
    }
}
