//
//  OnboardingTrainingExperienceStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

struct OnboardingTrainingExperienceStepView: View {
    @Binding var selectedExperience: TrainingExperience?
    @Environment(\.colorScheme) private var colorScheme
    
 
    let onNext: () -> Void
    
    @State private var tempSelection: TrainingExperience = .beginner
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "figure.stairs")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.primary)
              
            
            Text("This helps us decide how aggressive we can be with deficits and surpluses without hurting your performance.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                ForEach(TrainingExperience.allCases, id: \.self) { level in
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
            if let existing = selectedExperience {
                tempSelection = existing
            }
        }
    }
    
    private func handleNext() {
        selectedExperience = tempSelection
        errorMessage = nil
        onNext()
    }
}


#Preview {
    OnboardingTrainingExperienceStepView(selectedExperience: .constant(.beginner), onNext: { print("")})
}
