//
//  OnboardingFlowView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

enum OnboardingStep: Hashable, CaseIterable {
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
    case appleHealth
    case notifications
    case summary

    var analyticsName: String {
        switch self {
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
        case .appleHealth:
            return "apple_health"
        case .notifications:
            return "notifications"
        case .summary:
            return "summary"
        }
    }

    /// The two busiest steps get only the small face, so their content stays high.
    var illustration: OnboardingIllustration {
        switch self {
        case .liftEatsIntro, .gender: .plate(.wonder)
        case .liftEatsDifference, .age: .plate(.write)
        case .height: .plate(.stretch)
        case .weight: .plate(.weigh)
        case .activityLevel: .plate(.walk)
        case .goal, .goalWeight: .plate(.lookAhead)
        case .appleHealth: .plate(.phone)
        case .notifications: .plate(.bell)
        case .loggingTips, .summary: .face
        }
    }
}

enum OnboardingIllustration: Equatable {
    case plate(PlateMascot.Move)
    case face
}

struct OnboardingFlowView: View {
    var onExit: (() -> Void)? = nil
    /// Called when the last step finishes successfully.
    let onFinished: (OnboardingAnswers) -> Void

    @EnvironmentObject private var healthWeightSync: HealthWeightSyncService
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var data = OnboardingAnswers()
    @State private var path: [OnboardingStep] = []

    private var step: OnboardingStep { path.last ?? .liftEatsIntro }

    // MARK: - Step order + progress

    /// Gates both the step's place in the order and what points at it. Read
    /// twice, so it lives in one place.
    private var healthStepAvailable: Bool { healthWeightSync.isAvailable }

    private var orderedSteps: [OnboardingStep] {
        var steps: [OnboardingStep] = [.liftEatsIntro, .liftEatsDifference]
        steps += [.gender, .age, .height, .weight, .activityLevel, .goal]
        // Maintain has no goal weight, so it skips that step.
        if data.goalType != .maintain { steps.append(.goalWeight) }
        steps.append(.loggingTips)
        // No Health database on this hardware means no step to show.
        if healthStepAvailable { steps.append(.appleHealth) }
        steps += [.notifications, .summary]
        return steps
    }

    private var currentIndex: Int { index(of: step) }

    /// Pages still in the stack redraw when the top one changes, so each page
    /// reads its own position rather than `currentIndex`.
    private func index(of step: OnboardingStep) -> Int {
        orderedSteps.firstIndex(of: step) ?? 0
    }

    private var progress: CGFloat {
        CGFloat(currentIndex + 1) / CGFloat(orderedSteps.count)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.circaBarTrack)

                Capsule()
                    .fill(Color.circaAccent)
                    .frame(width: geo.size.width * progress)
                    .animation(.spring(response: 0.28, dampingFraction: 0.9), value: progress)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Navigation

    private func go(to newStep: OnboardingStep) {
        // A second tap while the push is still running would stack the step twice.
        guard path.last != newStep else { return }
        path.append(newStep)
    }

    private func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // MARK: - Step content

    /// The header above the stack stands in for the navigation bar.
    private func page(_ step: OnboardingStep) -> some View {
        VStack(spacing: 0) {
            illustration(for: step)
            stepView(for: step)
        }
        .circaPaper()
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func illustration(for step: OnboardingStep) -> some View {
        switch step.illustration {
        case .plate(let move):
            PlateMascot(move: move)
                .frame(height: dynamicTypeSize.isAccessibilitySize ? 90 : 130)
                .frame(maxWidth: .infinity)
        case .face:
            Image("PlateFace")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Circa.Space.screenMargin)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func stepView(for step: OnboardingStep) -> some View {
        switch step {
        case .liftEatsIntro:
            liftEatsIntro(
                onNext: { go(to: .liftEatsDifference) }
            )

        case .liftEatsDifference:
            OnboardingLiftEats(
                onNext: { go(to: .gender) }
            )

        case .gender:
            OnboardingGenderStepView(
                gender: $data.gender,
                onNext: { go(to: .age) }
            )

        case .age:
            OnboardingAgeStepView(
                age: $data.age,
                onNext: { go(to: .height) }
            )

        case .height:
            OnboardingHeightStepView(
                heightCm: $data.heightCm,
                onNext: { go(to: .weight) }
            )

        case .weight:
            OnboardingWeightStepView(
                weightKg: $data.weightKg,
                onNext: { go(to: .activityLevel) }
            )

        case .activityLevel:
            OnboardingActivityLevelStepView(
                selectedLevel: $data.activityLevel,
                onNext: { go(to: .goal) }
            )

        case .goal:
            OnboardingTrainingGoalStepView(
                selectedGoal: $data.goalType,
                heightCm: data.heightCm,
                weightKg: data.weightKg,
                onFinish: {
                    if data.goalType == .maintain { data.goalWeightKg = nil }
                    go(to: data.goalType == .maintain ? .loggingTips : .goalWeight)
                }
            )

        case .goalWeight:
            if let goalType = data.goalType, let weight = data.weightKg, let height = data.heightCm {
                OnboardingGoalWeightStepView(
                    goal: goalType,
                    currentWeightKg: weight,
                    heightCm: height,
                    goalWeightKg: $data.goalWeightKg,
                    stepPosition: index(of: step) + 1,
                    stepCount: orderedSteps.count,
                    onNext: { go(to: .loggingTips) }
                )
            }

        case .loggingTips:
            OnboardingLoggingTipsStepView(
                // Destinations here are literal, not derived from
                // `orderedSteps`, so a skipped Health step has to be skipped
                // twice — once in the order, once in what points at it.
                onNext: { go(to: healthStepAvailable ? .appleHealth : .notifications) }
            )

        case .appleHealth:
            OnboardingAppleHealthStepView(
                stepPosition: index(of: step) + 1,
                stepCount: orderedSteps.count,
                onFinished: { go(to: .notifications) }
            )

        case .notifications:
            OnboardingNotificationsStepView(
                stepPosition: index(of: step) + 1,
                stepCount: orderedSteps.count,
                onFinished: { go(to: .summary) }
            )

        case .summary:
            OnboardingSummaryStepView(answers: data, onStartTracking: finishOnboarding(editedTargets:))
        }
    }

    private func finishOnboarding(editedTargets: Macros?) {
        // Guard that every required answer is present before finishing. The plan
        // step disables its final action until these are set, so this is a safety net.
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
        VStack(spacing: 12) {

            HStack(spacing: 12) {
                if currentIndex > 0 || onExit != nil {
                    Button {
                        if currentIndex == 0 { onExit?() } else { goBack() }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundStyle(Color.circaInk)
                            .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                            .background(Color.circaCard, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(currentIndex == 0 ? "Back to welcome" : "Previous step")
                } else {
                    Color.clear
                        .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                }

                progressBar
            }
            .padding(.horizontal)
            .padding(.top, 8)

            NavigationStack(path: $path) {
                page(.liftEatsIntro)
                    .navigationDestination(for: OnboardingStep.self) { page($0) }
            }
        }
        .circaPaper()
        .sensoryFeedback(trigger: path) { old, new in
            new.count > old.count ? .impact(weight: .light) : .impact(flexibility: .soft)
        }
        .onAppear {
            FirebaseTelemetryService.logOnboardingEvent("step_viewed", step: step.analyticsName)
        }
        .onChange(of: step) { _, newStep in
            FirebaseTelemetryService.logOnboardingEvent("step_viewed", step: newStep.analyticsName)
        }
    }
}

#Preview {
    OnboardingFlowView { answers in
        print("Finished onboarding with:", answers)
    }
    .environmentObject(SubscriptionViewModel())
    .environmentObject(HealthWeightSyncService())
}
