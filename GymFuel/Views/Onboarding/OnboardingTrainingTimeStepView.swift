//
//  OnboardingTrainingTimeStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 11/12/2025.
//

import SwiftUI

/// Step: What time of day do you *usually* train?
struct OnboardingTrainingTimeStepView: View {
    @Binding var selectedTime: TrainingTimeOfDay?
    @Environment(\.colorScheme) private var colorScheme

    let onNext: () -> Void
    
    @State private var tempSelection: TrainingTimeOfDay = .evening
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            
            Image(systemName: "clock.circle")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.primary)
            
            Text("We’ll use this to time your carbs and key meals around your workouts.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            VStack(spacing: 12) {
                ForEach(TrainingTimeOfDay.allCases, id: \.self) { time in
                    Button {
                        tempSelection = time
                        errorMessage = nil
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                           
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(time.displayName)
                                    .font(.headline)
                                Text(time.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            if tempSelection == time {
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
                                    tempSelection == time
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
            if let existing = selectedTime {
                tempSelection = existing
            }
        }
    }
    
    private func handleNext() {
        selectedTime = tempSelection
        errorMessage = nil
        onNext()
    }
}


#Preview {
    OnboardingTrainingTimeStepView(selectedTime: .constant(.evening), onNext: { print("")})
}
