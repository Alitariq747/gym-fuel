//
//  OnboardingNameStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

struct OnboardingNameStepView: View {
    let onNext: () -> Void
    let onSkip: () -> Void
    @Binding var name: String
    
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            AdaptiveScrollContainer {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        CircaSectionLabel("About you")
                        Text("What should we call you?")
                            .font(.circaTitle)
                            .foregroundStyle(Color.circaInk)
                        Text("Your name makes this journal yours. You can change it later.")
                            .font(.circaBody)
                            .foregroundStyle(Color.circaInk2)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        CircaSectionLabel("Name")
                        TextField("Your name", text: nameBinding)
                            .font(.circaRow)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .padding(14)
                            .frame(minHeight: 52)
                            .background(ProfileCardBackground())
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.circaCaption)
                            .foregroundStyle(Color.circaDanger)
                    }
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.top, 18)
            }

            VStack(spacing: 8) {
                Button(action: handleNext) {
                    Text("Continue").frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary, height: 52))

                Button("Skip for now", action: onSkip)
                    .buttonStyle(.circa(.quiet))
            }
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.bottom, 16)
        }
        .circaPaper()
    }
    
    private var nameBinding: Binding<String> {
        Binding(
            get: { name },
            set: { newValue in
                name = newValue
                if errorMessage != nil {
                    errorMessage = nil
                }
            }
        )
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
    OnboardingNameStepView(onNext: { print("next")}, onSkip: { print("skip")}, name: .constant(""))
}
