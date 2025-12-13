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
    
    let onBack: () -> Void
    let onNext: () -> Void
    
    @State private var tempSelection: NonTrainingActivityLevel = .mostlySitting
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Your daily activity")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            
            Text("This tells us how active you are outside the gym so we can set your baseline calories, especially on rest days.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                ForEach(NonTrainingActivityLevel.allCases, id: \.self) { level in
                    Button {
                        tempSelection = level
                        errorMessage = nil
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .stroke(lineWidth: tempSelection == level ? 6 : 2)
                                .frame(width: 22, height: 22)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(level.displayName)
                                    .font(.headline)
                                Text(level.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    tempSelection == level
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
        .navigationTitle("Activity Level")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    onBack()
                }
            }
        }
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


//#Preview {
//    OnboardingActivityLevelStepView()
//}
