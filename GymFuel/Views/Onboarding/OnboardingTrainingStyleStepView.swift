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
    
    let onBack: () -> Void
    let onNext: () -> Void
    
    @State private var tempSelection: TrainingStyle = .strength
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Your training style")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            
            Text("This helps us bias your fueling. Endurance and mixed training often need more carbs, for example.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                ForEach(TrainingStyle.allCases, id: \.self) { style in
                    Button {
                        tempSelection = style
                        errorMessage = nil
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .stroke(lineWidth: tempSelection == style ? 6 : 2)
                                .frame(width: 22, height: 22)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(style.displayName)
                                    .font(.headline)
                                Text(style.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    tempSelection == style
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
        .navigationTitle("Training Style")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    onBack()
                }
            }
        }
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
    OnboardingTrainingStyleStepView(selectedStyle: .constant(.mixed), onBack: { print("")}, onNext: { print("")})
}
