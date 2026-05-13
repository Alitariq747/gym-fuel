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
                
            VStack(spacing: 18) {
                genderOption(.male, emoji: "👨", subtitle: "Use male-based macro equations.", tint: .fuelBlue)
                genderOption(.female, emoji: "👩", subtitle: "Use female-based macro equations.", tint: .pink)
                genderOption(.preferNotToSay, emoji: "✨", subtitle: "Keep things private and balanced.", tint: .fuelOrange)
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
    
    private func genderOption(_ option: Gender, emoji: String, subtitle: String, tint: Color) -> some View {
        Button {
            gender = option
        } label: {
            HStack(spacing: 14) {
                Text(emoji)
                    .font(.title2)
                    .frame(width: 46, height: 46)
                    .background(tint.opacity(colorScheme == .dark ? 0.22 : 0.13), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.displayName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(gender == option ? tint : Color(.secondarySystemBackground), lineWidth: gender == option ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func handleNext() {
        onNext()
    }
}

#Preview {
    OnboardingGenderStepView(name: "Ali", gender: .constant(.female), onNext: { print("")})
}
