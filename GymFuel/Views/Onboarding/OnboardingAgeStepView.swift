//
//  OnboardingAgeStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

struct OnboardingAgeStepView: View {
    @Binding var age: Int?
    let onNext: () -> Void

    @State private var ageText: String = ""
    @State private var errorMessage: String?

    var body: some View {
        OnboardingMetricPage(
            title: "How old are you?",
            detail: "Age helps set a starting calorie estimate. This plan is for adults 18 and older.",
            onContinue: handleNext
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Age")
                    .font(.circaRow)
                    .foregroundStyle(Color.circaInk2)

                HStack(spacing: 12) {
                    TextField("Age", text: ageBinding)
                        .keyboardType(.numberPad)
                        .font(.circaMonoLarge)
                        .foregroundStyle(Color.circaInk)
                    Spacer(minLength: 0)
                    Text("years")
                        .font(.circaRow)
                        .foregroundStyle(Color.circaInk2)
                }
                .padding(16)
                .frame(minHeight: 68)
                .background(Color.circaCard, in: RoundedRectangle(cornerRadius: Circa.Radius.cardSmall))
                .overlay {
                    RoundedRectangle(cornerRadius: Circa.Radius.cardSmall)
                        .strokeBorder(errorMessage == nil ? Color.circaCardBorder : Color.circaDanger, lineWidth: 1)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaDanger)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear {
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
        let enteredAge = Int(ageText)
        if let problem = SafetyLimits.ageProblem(enteredAge) {
            errorMessage = problem
            return
        }
        
        errorMessage = nil
        age = enteredAge
        onNext()
    }
}


#Preview {
    OnboardingAgeStepView(age: .constant(38), onNext: {print("")})
}
