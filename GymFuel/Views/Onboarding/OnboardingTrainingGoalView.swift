//
//  OnboardingTrainingGoalView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

struct OnboardingTrainingGoalStepView: View {
    @Binding var selectedGoal: GoalType?
    @Environment(\.colorScheme) private var colorScheme
 
    let onFinish: () -> Void
    
    @State private var tempSelection: GoalType = .leanBulk
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("🎯")
                .font(.system(size: 48))
                .frame(width: 96, height: 96)
                .background(Color.fuelOrange.opacity(0.14), in: Circle())
            
            Text("Choose your Training Goal")
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            VStack(spacing: 12) {
                ForEach(GoalType.allCases, id: \.self) { goal in
                    goalOption(goal)
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
    
    private func goalOption(_ goal: GoalType) -> some View {
        Button {
            tempSelection = goal
            errorMessage = nil
        } label: {
            HStack(alignment: .top, spacing: 14) {
                goalSymbol(goal)
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.displayName)
                        .font(.headline.weight(.semibold))
                    Text(goal.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(tempSelection == goal ? Color.fuelOrange : Color.gray.opacity(0.24), lineWidth: tempSelection == goal ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func goalSymbol(_ goal: GoalType) -> some View {
        Image(systemName: goal.symbolName)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color.primary)
            .frame(width: 44, height: 44)
            .background(Color(.systemBackground), in: Circle())
            .overlay {
                Circle()
                    .stroke(Color.fuelOrange.opacity(colorScheme == .dark ? 0.24 : 0.16), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 8, y: 4)
    }

    private func handleFinish() {
       
        selectedGoal = tempSelection
        errorMessage = nil
        onFinish()
    }
}


#Preview {
    OnboardingTrainingGoalStepView(selectedGoal: .constant(.cut), onFinish: { print("")})
}
