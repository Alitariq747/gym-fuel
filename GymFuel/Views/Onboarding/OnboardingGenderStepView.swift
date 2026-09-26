//
//  OnboardingGenderStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import SwiftUI

struct OnboardingGenderStepView: View {
    @Binding var gender: Gender
    let onNext: () -> Void

    var body: some View {
        OnboardingMetricPage(
            title: "What's your gender?",
            detail: "This helps us calculate better calorie and macro goals.",
            onContinue: onNext
        ) {
            VStack(spacing: 12) {
                ForEach(Gender.allCases, id: \.rawValue) { option in
                    genderOption(option)
                }
            }
        }
    }

    private func genderOption(_ option: Gender) -> some View {
        let isSelected = gender == option

        return Button {
            gender = option
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: option.iconName)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Color.circaInk2)
                    .frame(width: 26)
                    .accessibilityHidden(true)

                Text(option.displayName)
                    .font(.circaEntryTitle)
                    .foregroundStyle(Color.circaInk)

                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.circaAccent : Color.circaInk3)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: Circa.minHitTarget)
            .background(Color.circaCard, in: RoundedRectangle(cornerRadius: Circa.Radius.cardSmall))
            .overlay {
                RoundedRectangle(cornerRadius: Circa.Radius.cardSmall)
                    .strokeBorder(isSelected ? Color.circaAccent : Color.circaCardBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

#Preview {
    OnboardingGenderStepView(gender: .constant(.female), onNext: { print("")})
}
