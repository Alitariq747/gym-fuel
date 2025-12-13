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
    
    let onBack: () -> Void
    let onNext: () -> Void
    
    @State private var tempSelection: TrainingTimeOfDay = .evening
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Text("When do you usually train?")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            
            Text("We’ll use this to time your carbs and key meals around your workouts.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                ForEach(TrainingTimeOfDay.allCases, id: \.self) { time in
                    Button {
                        tempSelection = time
                        errorMessage = nil
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .stroke(lineWidth: tempSelection == time ? 6 : 2)
                                .frame(width: 22, height: 22)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(time.displayName)
                                    .font(.headline)
                                Text(time.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    tempSelection == time
                                    ? Color.accentColor
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
            
            HStack {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)
                
                Button {
                    handleNext()
                } label: {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Training Time")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    onBack()
                }
            }
        }
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
    OnboardingTrainingTimeStepView(selectedTime: .constant(.evening), onBack: { print("")}, onNext: { print("")})
}
