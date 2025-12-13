//
//  OnboardingNameStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

struct OnboardingNameStepView: View {
    
    let onNext: () -> Void
    @Binding var name: String
    
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
                   Text("Welcome to GymFuel")
                       .font(.largeTitle.bold())
                       .multilineTextAlignment(.center)
                   
                   Text("Let’s start with your name.")
                       .font(.body)
                       .foregroundStyle(.secondary)
                       .multilineTextAlignment(.center)
                   
                   VStack(alignment: .leading, spacing: 8) {
                       Text("Name")
                           .font(.headline)
                       TextField("Your name", text: $name)
                           .textInputAutocapitalization(.words)
                           .textFieldStyle(.roundedBorder)
                   }
                   
                   if let errorMessage {
                       Text(errorMessage)
                           .font(.footnote)
                           .foregroundStyle(.red)
                           .frame(maxWidth: .infinity, alignment: .leading)
                   }
                   
                   Button {
                       handleNext()
                   } label: {
                       Text("Next")
                           .frame(maxWidth: .infinity)
                   }
                   .buttonStyle(.borderedProminent)
                   .padding(.top, 8)
                   
                   Spacer()
               }
               .padding()
               .navigationTitle("Your Name")
               .navigationBarTitleDisplayMode(.inline)    }
    
    private func handleNext() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            errorMessage = "Name is required."
            return
        }
        errorMessage = nil
        name = trimmed
        onNext()
    }
    
}

#Preview {
    OnboardingNameStepView(onNext: { print("next")}, name: .constant("Ali"))
}
