//
//  OnboardingTrainingGoalView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

struct OnboardingTrainingGoalStepView: View {
    @Binding var selectedGoal: TrainingGoal?
    
    let onBack: () -> Void
    let onFinish: () -> Void
    
    @State private var tempSelection: TrainingGoal = .performance
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Text("How should we fuel you?")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            
            Text("Pick the goal that best matches what you want over the next few months.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                ForEach(TrainingGoal.allCases, id: \.self) { goal in
                    Button {
                        tempSelection = goal
                        errorMessage = nil
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .stroke(lineWidth: tempSelection == goal ? 6 : 2)
                                .frame(width: 22, height: 22)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.displayName)
                                    .font(.headline)
                                Text(goal.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(tempSelection == goal ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
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
            
            HStack {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)
                
                Button {
                    handleFinish()
                } label: {
                    Text("Finish")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Training Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    onBack()
                }
            }
        }
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
    OnboardingTrainingGoalStepView(selectedGoal: .constant(.fatLoss), onBack: { print("")}, onFinish: { print("")})
}
