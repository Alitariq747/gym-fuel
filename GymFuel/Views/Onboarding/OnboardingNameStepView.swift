//
//  OnboardingNameStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

struct OnboardingNameStepView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let onNext: () -> Void
    @Binding var name: String
    
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Welcome to LiftEats")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            
            Text("What should we call you ?")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Enter Name")
                    .font(.subheadline)
                TextField("", text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
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
    }
    
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
    OnboardingNameStepView(onNext: { print("next")}, name: .constant(""))
}
