//
//  OnboardingTrainingGoalView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

struct OnboardingTrainingGoalStepView: View {
    @Binding var selectedGoal: TrainingGoal?
    @Environment(\.colorScheme) private var colorScheme
 
    let onFinish: () -> Void
    
    @State private var tempSelection: TrainingGoal = .performance
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dot.scope")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.primary)
            
            Text("Pick the goal that best matches what you want over the next few months.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            VStack(spacing: 12) {
                ForEach(TrainingGoal.allCases, id: \.self) { goal in
                    Button {
                        tempSelection = goal
                        errorMessage = nil
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                          
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.displayName)
                                    .font(.headline)
                                Text(goal.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            if tempSelection == goal {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.primary)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(Color.gray.opacity(0.3))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(tempSelection == goal ? Color.primary : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            Button {
                handleFinish()
            } label: {
                Text("Finish")
                    .font(.headline).bold()
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.black, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .onAppear {
            if let existing = selectedGoal {
                tempSelection = existing
            }
        }
    }
    
    private func handleFinish() {
       
        selectedGoal = tempSelection
        errorMessage = nil
        onFinish()
    }
}


#Preview {
    OnboardingTrainingGoalStepView(selectedGoal: .constant(.fatLoss), onFinish: { print("")})
}
