//
//  OnboardingTrainingStyleStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

/// Step: What is your primary training style?
/// 
struct OnboardingTrainingStyleStepView: View {
    @Binding var selectedStyle: TrainingStyle?
    @Environment(\.colorScheme) private var colorScheme
    
    
    let onNext: () -> Void
    
    @State private var tempSelection: TrainingStyle = .strength
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.mixed.cardio")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.primary)
            
            
            
            Text("This helps us bias your fueling. Endurance and mixed training often need more carbs, for example.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            VStack(spacing: 12) {
                ForEach(TrainingStyle.allCases, id: \.self) { style in
                    Button {
                        tempSelection = style
                        errorMessage = nil
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
  
                            VStack(alignment: .leading, spacing: 4) {
                                Text(style.displayName)
                                    .font(.headline)
                                Text(style.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            if tempSelection == style {
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
                                    tempSelection == style
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
            if let existing = selectedStyle {
                tempSelection = existing
            }
        }
    }
    
    private func handleNext() {
        selectedStyle = tempSelection
        errorMessage = nil
        onNext()
    }
}


#Preview {
    OnboardingTrainingStyleStepView(selectedStyle: .constant(.mixed), onNext: { print("")})
}
