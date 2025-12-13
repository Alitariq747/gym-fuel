//
//  OnboardingAgeStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

struct OnboardingAgeStepView: View {
    @Binding var age: Int?
    
    let onBack: () -> Void
    let onNext: () -> Void
    
    @State private var ageText: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Just a bit more")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            
            Text("Your age helps us estimate your calorie needs more accurately.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Age")
                    .font(.headline)
                TextField("e.g. 25", text: $ageText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
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
        .navigationTitle("Your Age")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    onBack()
                }
            }
        }
        .onAppear {
            // Pre-fill if we already have an age
            if let currentAge = age, ageText.isEmpty {
                ageText = String(currentAge)
            }
        }
    }
    
    private func handleNext() {
        guard let value = Int(ageText), value > 0, value < 120 else {
            errorMessage = "Please enter a valid age."
            return
        }
        
        errorMessage = nil
        age = value
        onNext()
    }
}


#Preview {
    OnboardingAgeStepView(age: .constant(38), onBack: {print("")}, onNext: {print("")})
}
