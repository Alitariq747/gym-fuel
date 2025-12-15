//
//  OnboardingAgeStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

struct OnboardingAgeStepView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var age: Int?
    

    let onNext: () -> Void
    
    @State private var ageText: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Please enter your age")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            
            Text("Your age helps us estimate your macros more accurately.")
                .font(.body)
                .foregroundStyle(.secondary)
//                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Enter Age")
                    .font(.subheadline)
                TextField("", text: $ageText)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.leading, 12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
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
                Text("Confirm")
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
    OnboardingAgeStepView(age: .constant(38), onNext: {print("")})
}
