//
//  OnboardingGenderStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

struct OnboardingGenderStepView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let name: String
    @Binding var gender: String
    
    let onNext: () -> Void
  
    
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
                 
                  
                  Text("Whats your gender ?")
                        .font(.title).bold()
                      .foregroundStyle(.primary)
            
                Text("This lets us calculate your target macros more precisely")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                    Spacer()
                  
                 // Vstack for gender
                
            // male button
            VStack(spacing: 18) {
                Button {
                    gender = "male"
                } label: {
                    HStack(spacing: 8) {
                        Text("♂")
                            .font(.title2)
                            .foregroundStyle(.primary)
                        Text("Male")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                        gender == "male" ?
                        (Color.primary) : Color(.secondarySystemBackground), lineWidth: gender == "male" ? 2 : 1))
                }
                .buttonStyle(.plain)
                
                // female button
                Button {
                    gender = "female"
                } label: {
                    HStack {
                        Text("♀")
                            .font(.title2)
                            .foregroundStyle(.primary)
                        Text("Female")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                        gender == "female" ?
                        (Color.primary) : Color(.secondarySystemBackground), lineWidth: gender == "female" ? 2 : 1))
                }
                .buttonStyle(.plain)
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
        guard !gender.isEmpty else {
            errorMessage = "Please select a gender."
            return
        }
        errorMessage = nil
        onNext()
    }
}

#Preview {
    OnboardingGenderStepView(name: "Ali", gender: .constant("female"), onNext: { print("")})
}
