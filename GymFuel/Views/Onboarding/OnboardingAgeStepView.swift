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
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 28)

            Text("🎂")
                .font(.system(size: 58))
                .frame(width: 116, height: 116)
                .background(
                    LinearGradient(
                        colors: [Color.fuelOrange.opacity(0.22), Color.fuelGreen.opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
                .frame(maxWidth: .infinity)

            Text("Age helps calibrate your baseline energy needs before activity and goals are added.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter Age")
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 10) {
                    TextField("", text: ageBinding)
                        .keyboardType(.numberPad)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Text("years")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(errorMessage == nil ? Color(.secondarySystemBackground) : Color.fuelRed, lineWidth: 1)
                )
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
        .onAppear {
            // Pre-fill if we already have an age
            if let currentAge = age, ageText.isEmpty {
                ageText = String(currentAge)
            }
        }
    }
    
    private var ageBinding: Binding<String> {
        Binding(
            get: { ageText },
            set: { newValue in
                ageText = newValue.filter(\.isNumber)
                if errorMessage != nil {
                    errorMessage = nil
                }
            }
        )
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
