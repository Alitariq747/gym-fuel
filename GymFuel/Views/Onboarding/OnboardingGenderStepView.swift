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
    @Binding var gender: Gender
    
    let onNext: () -> Void
  
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
                
            // gender buttons
            VStack(spacing: 18) {
                Button {
                    gender = .male
                } label: {
                    HStack(spacing: 8) {
                        Text(Gender.male.symbol)
                            .font(.title2)
                            .foregroundStyle(.primary)
                        Text(Gender.male.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                        gender == .male ?
                        (Color.primary) : Color(.secondarySystemBackground), lineWidth: gender == .male ? 2 : 1))
                }
                .buttonStyle(.plain)
                
                // female button
                Button {
                    gender = .female
                } label: {
                    HStack {
                        Text(Gender.female.symbol)
                            .font(.title2)
                            .foregroundStyle(.primary)
                        Text(Gender.female.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                        gender == .female ?
                        (Color.primary) : Color(.secondarySystemBackground), lineWidth: gender == .female ? 2 : 1))
                }
                .buttonStyle(.plain)
                
                // prefer not to say button
                Button {
                    gender = .preferNotToSay
                } label: {
                    HStack {
                        Text(Gender.preferNotToSay.symbol)
                            .font(.title2)
                            .foregroundStyle(.primary)
                        Text(Gender.preferNotToSay.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                        gender == .preferNotToSay ?
                        (Color.primary) : Color(.secondarySystemBackground), lineWidth: gender == .preferNotToSay ? 2 : 1))
                }
                .buttonStyle(.plain)
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
        onNext()
    }
}

#Preview {
    OnboardingGenderStepView(name: "Ali", gender: .constant(.female), onNext: { print("")})
}
