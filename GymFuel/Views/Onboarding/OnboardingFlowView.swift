//
//  OnboardingFlowView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

private enum OnboardingStep: Hashable {
    case name
    case liftEatsIntro
    case liftEatsDifference
    case gender
    case age
    case height
    case weight
    case activityLevel
    case goal
    case goalWeight
    case loggingTips
    case notifications
    case summary

    var analyticsName: String {
        switch self {
        case .name:
            return "name"
        case .liftEatsIntro:
            return "lift_eats_intro"
        case .liftEatsDifference:
            return "lift_eats_difference"
        case .gender:
            return "gender"
        case .age:
            return "age"
        case .height:
            return "height"
        case .weight:
            return "weight"
        case .activityLevel:
            return "activity_level"
        case .goal:
            return "goal"
        case .goalWeight:
            return "goal_weight"
        case .loggingTips:
            return "logging_tips"
        case .notifications:
            return "notifications"
        case .summary:
            return "summary"
        }
    }
}

struct OnboardingFlowView: View {
    /// Name already supplied by the sign-in provider. Empty when none is available.
    var prefilledName: String = ""
    /// Whether to ask for a name. Only email/password accounts have no provider-supplied name.
    var showsNameStep: Bool = true
    /// Called when the last step finishes successfully.
    let onFinished: (OnboardingAnswers) -> Void

    @State private var data = OnboardingAnswers()
    @State private var step: OnboardingStep = .liftEatsIntro

    // MARK: - Step order + progress

    private var orderedSteps: [OnboardingStep] {
        var steps: [OnboardingStep] = [.liftEatsIntro, .liftEatsDifference]
        if showsNameStep { steps.append(.name) }
        steps += [.gender, .age, .height, .weight, .activityLevel, .goal]
        // Maintain has no goal weight, so it skips that step.
        if data.goalType != .maintain { steps.append(.goalWeight) }
        steps += [.loggingTips, .notifications, .summary]
        return steps
    }

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
                onSkip: { go(to: .gender, direction: .forward) },
                name: $data.name
            )

        case .liftEatsIntro:
            liftEatsIntro(
                onNext: { go(to: .liftEatsDifference, direction: .forward) }
            )

        case .liftEatsDifference:
            OnboardingLiftEats(
                onNext: { go(to: showsNameStep ? .name : .gender, direction: .forward) }
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
                selectedLevel: $data.activityLevel,
                onNext: { go(to: .goal, direction: .forward) }
            )

        case .goal:
            OnboardingTrainingGoalStepView(
                selectedGoal: $data.goalType,
                heightCm: data.heightCm,
                weightKg: data.weightKg,
                onFinish: {
                    if data.goalType == .maintain { data.goalWeightKg = nil }
                    go(to: data.goalType == .maintain ? .loggingTips : .goalWeight, direction: .forward)
                }
            )

        case .goalWeight:
            if let goalType = data.goalType, let weight = data.weightKg, let height = data.heightCm {
                OnboardingGoalWeightStepView(
                    goal: goalType,
                    currentWeightKg: weight,
                    heightCm: height,
                    goalWeightKg: $data.goalWeightKg,
                    stepPosition: currentIndex + 1,
                    stepCount: orderedSteps.count,
                    onNext: { go(to: .loggingTips, direction: .forward) }
                )
            }

        case .loggingTips:
            OnboardingLoggingTipsStepView(
                onNext: { go(to: .notifications, direction: .forward) }
            )

        case .notifications:
            OnboardingNotificationsStepView(
                stepPosition: currentIndex + 1,
                stepCount: orderedSteps.count,
                onFinished: { go(to: .summary, direction: .forward) }
            )

        case .summary:
            OnboardingSummaryStepView(answers: data, onStartTracking: finishOnboarding(editedTargets:))
        }
    }

    private func finishOnboarding(editedTargets: Macros?) {
        // Guard that every required answer is present before finishing. The plan
        // step disables Start writing until these are set, so this is a safety net.
        guard
            data.age != nil,
            data.heightCm != nil,
            data.weightKg != nil,
            data.goalType != nil,
            data.activityLevel != nil
        else { return }

        FirebaseTelemetryService.logOnboardingEvent("finish_tapped", step: step.analyticsName)
        // Edits join the answers only here, so going back to change an answer
        // never carries old numbers forward.
        var answers = data
        answers.editedTargets = editedTargets
        onFinished(answers)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                FirebaseTelemetryService.logOnboardingEvent("step_viewed", step: step.analyticsName)
            }
            .task(id: prefilledName) {
                let trimmed = prefilledName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, data.name.isEmpty else { return }
                data.name = trimmed
            }
            .onChange(of: step) { _, newStep in
                FirebaseTelemetryService.logOnboardingEvent("step_viewed", step: newStep.analyticsName)
            }
        }
    }
}

#Preview {
    OnboardingFlowView { answers in
        print("Finished onboarding with:", answers)
    }
    .environmentObject(SubscriptionViewModel())
}
