//
//  OnboardingTrainingGoalView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

struct OnboardingTrainingGoalStepView: View {
    @Binding var selectedGoal: GoalType?
    /// From the height and weight steps. *Lose fat* needs both to judge BMI.
    let heightCm: Double?
    let weightKg: Double?
 
    let onFinish: () -> Void
    
    @State private var tempSelection: GoalType = .leanBulk
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            AdaptiveScrollContainer {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        CircaSectionLabel("Your plan")
                        Text("What are you working toward?")
                            .font(.circaTitle)
                            .foregroundStyle(Color.circaInk)
                        Text("Choose a direction for your starting targets. You can change it later.")
                            .font(.circaBody)
                            .foregroundStyle(Color.circaInk2)
                    }

                    VStack(spacing: 12) {
                        ForEach(GoalType.allCases, id: \.self) { goal in
                            goalOption(goal)
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.circaCaption)
                            .foregroundStyle(Color.circaDanger)
                    }
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.top, 18)
                .padding(.bottom, 20)
            }

            Button(action: handleFinish) {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(.circa(.primary, height: 52))
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.bottom, 16)
        }
        .circaPaper()
        .onAppear {
            // Only if it is still available: the user may have come back and
            // changed their weight since choosing it.
            if let existing = selectedGoal,
               SafetyLimits.goalProblem(existing, weightKg: weightKg, heightCm: heightCm) == nil {
                tempSelection = existing
            }
        }
    }
    
    private func goalOption(_ goal: GoalType) -> some View {
        let problem = SafetyLimits.goalProblem(goal, weightKg: weightKg, heightCm: heightCm)

        return Button {
            tempSelection = goal
            errorMessage = nil
        } label: {
            HStack(alignment: .top, spacing: 14) {
                goalSymbol(goal)
                    .opacity(problem == nil ? 1 : 0.45)
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.displayName)
                        .font(.circaRow.weight(.semibold))
                        .foregroundStyle(problem == nil ? Color.circaInk : Color.circaInk3)
                    Text(problem ?? goal.detail)
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaInk2)
                }
                Spacer()
                if tempSelection == goal {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.circaAccent)
                        .accessibilityHidden(true)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(ProfileCardBackground())
            .overlay(
                RoundedRectangle(cornerRadius: Circa.Radius.card, style: .continuous)
                    .strokeBorder(tempSelection == goal ? Color.circaAccent : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(problem != nil)
        .accessibilityAddTraits(tempSelection == goal ? [.isSelected] : [])
    }

    private func goalSymbol(_ goal: GoalType) -> some View {
        Image(systemName: goal.symbolName)
            .font(.circaRow)
            .foregroundStyle(Color.circaInk2)
            .frame(width: 44, height: 44)
            .background(Color.circaWell, in: RoundedRectangle(cornerRadius: Circa.Radius.thumb))
    }

    private func handleFinish() {
       
        selectedGoal = tempSelection
        errorMessage = nil
        onFinish()
    }
}


#Preview {
    OnboardingTrainingGoalStepView(selectedGoal: .constant(.cut), heightCm: 178, weightKg: 82, onFinish: { print("")})
}
