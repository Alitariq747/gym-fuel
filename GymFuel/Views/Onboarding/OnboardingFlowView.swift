//
//  OnboardingFlowView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

private struct OnboardingData {
    var name: String = ""
    var gender: Gender = .preferNotToSay
    var age: Int? = nil
    var heightCm: Double? = nil
    var weightKg: Double? = nil
    var goalType: GoalType? = nil
    var nonTrainingActivityLevel: NonTrainingActivityLevel? = nil
}

private enum OnboardingStep: Hashable {
    case name
    case gender
    case age
    case height
    case weight
    case activityLevel
    case goal
}

struct OnboardingFlowView: View {
    /// Called when the last step finishes successfully.
    let onFinished: (String, Gender, Int, Double, Double, GoalType, NonTrainingActivityLevel) -> Void

    @State private var data = OnboardingData()
    @State private var step: OnboardingStep = .name

    // MARK: - Step order + progress

    private let orderedSteps: [OnboardingStep] = [
        .name, .gender, .age, .height, .weight,
        .activityLevel, .goal
    ]

    private var currentIndex: Int {
        orderedSteps.firstIndex(of: step) ?? 0
    }

    private var progress: CGFloat {
        CGFloat(currentIndex + 1) / CGFloat(orderedSteps.count)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.secondarySystemBackground))

                Capsule()
                    .fill(Color.primary)
                    .frame(width: geo.size.width * progress)
                    .animation(.spring(response: 0.28, dampingFraction: 0.9), value: progress)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Directional transitions

    private enum NavDirection { case forward, backward }
    @State private var navDirection: NavDirection = .forward

    private var stepTransition: AnyTransition {
        switch navDirection {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .backward:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }

    private func go(to newStep: OnboardingStep, direction: NavDirection) {
        navDirection = direction
        withAnimation(.easeInOut(duration: 0.25)) {
            step = newStep
        }
    }

    private func goBack() {
        let idx = currentIndex
        guard idx > 0 else { return }
        go(to: orderedSteps[idx - 1], direction: .backward)
    }

    // MARK: - Step content

    @ViewBuilder
    private var stepView: some View {
        switch step {
        case .name:
            OnboardingNameStepView(
                onNext: { go(to: .gender, direction: .forward) },
                name: $data.name
            )

        case .gender:
            OnboardingGenderStepView(
                name: data.name,
                gender: $data.gender,
                onNext: { go(to: .age, direction: .forward) }
            )

        case .age:
            OnboardingAgeStepView(
                age: $data.age,
                onNext: { go(to: .height, direction: .forward) }
            )

        case .height:
            OnboardingHeightStepView(
                heightCm: $data.heightCm,
                onNext: { go(to: .weight, direction: .forward) }
            )

        case .weight:
            OnboardingWeightStepView(
                weightKg: $data.weightKg,
                onNext: { go(to: .activityLevel, direction: .forward) }
            )

        case .activityLevel:
            OnboardingActivityLevelStepView(
                selectedLevel: $data.nonTrainingActivityLevel,
                onNext: { go(to: .goal, direction: .forward) }
            )

        case .goal:
            OnboardingTrainingGoalStepView(
                selectedGoal: $data.goalType,
                onFinish: finishOnboarding
            )
        }
    }

    private func finishOnboarding() {
        guard
            let age = data.age,
            let height = data.heightCm,
            let weight = data.weightKg,
            let goalType = data.goalType,
            let activityLevel = data.nonTrainingActivityLevel
        else { return }

        onFinished(
            data.name, data.gender, age, height, weight,
            goalType, activityLevel
        )
    }


    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {

                HStack(spacing: 12) {
                    if currentIndex > 0 {
                        Button(action: goBack) {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                                .frame(width: 36, height: 36)
                                .background(Color(.secondarySystemBackground), in: Circle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(width: 36, height: 36)
                    }

                    progressBar
                }
                .padding(.horizontal)
                .padding(.top, 8)

                ZStack {
                    stepView
                        .transition(stepTransition)
                }
                .id(step)

                Spacer(minLength: 0)
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    OnboardingFlowView { name, gender, age, height, weight, goalType, activityLevel in
        print("Finished onboarding with:", name, gender, age, height, weight, goalType, activityLevel)
    }
}
