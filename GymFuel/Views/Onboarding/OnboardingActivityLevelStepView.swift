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
            Image(systemName: "bed.double")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.primary)
            
            
            Text("This tells us how active you are outside the gym so we can set your baseline calories, especially on rest days.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            VStack(spacing: 12) {
                ForEach(NonTrainingActivityLevel.allCases, id: \.self) { level in
                    Button {
                        tempSelection = level
                        errorMessage = nil
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                           
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(level.displayName)
                                    .font(.headline)
                                Text(level.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if tempSelection == level {
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
                                .stroke(
                                    tempSelection == level
                                    ? Color.primary
                                    : Color.gray.opacity(0.3),
                                    lineWidth: 1
                                )
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
    
    private func handleNext() {
        selectedLevel = tempSelection
        errorMessage = nil
        onNext()
    }
}


#Preview {
    OnboardingActivityLevelStepView(selectedLevel: .constant(.physicallyDemanding), onNext: { print("") })
}
