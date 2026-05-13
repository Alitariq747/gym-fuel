//
//  OnboardingActivityLevelStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 11/12/2025.
//

import SwiftUI

/// Step: What is your general activity level outside of workouts?
struct OnboardingActivityLevelStepView: View {
    @Binding var selectedLevel: NonTrainingActivityLevel?
    @Environment(\.colorScheme) private var colorScheme
    
    
    let onNext: () -> Void
    
    @State private var tempSelection: NonTrainingActivityLevel = .mostlySitting
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🚶")
                .font(.system(size: 48))
                .frame(width: 96, height: 96)
                .background(Color.fuelBlue.opacity(0.13), in: Circle())
            
            
            Text("Set your Activity Level")
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            VStack(spacing: 12) {
                ForEach(NonTrainingActivityLevel.allCases, id: \.self) { level in
                    activityOption(level)
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
                handleNext()
            } label: {
                Text("Next")
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
            if let existing = selectedLevel {
                tempSelection = existing
            }
        }
    }
    
    private func activityOption(_ level: NonTrainingActivityLevel) -> some View {
        Button {
            tempSelection = level
            errorMessage = nil
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Text(activityEmoji(for: level))
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(Color.fuelBlue.opacity(colorScheme == .dark ? 0.22 : 0.12), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(.headline.weight(.semibold))
                    Text(level.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(tempSelection == level ? Color.fuelBlue : Color.gray.opacity(0.24), lineWidth: tempSelection == level ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func activityEmoji(for level: NonTrainingActivityLevel) -> String {
        switch level {
        case .mostlySitting: return "🪑"
        case .somewhatActive: return "🏃"
        case .physicallyDemanding: return "🥵"
        }
    }

    private func handleNext() {
        selectedLevel = tempSelection
        errorMessage = nil
        onNext()
    }
}


#Preview {
    OnboardingActivityLevelStepView(selectedLevel: .constant(.physicallyDemanding), onNext: { print("") })
}
