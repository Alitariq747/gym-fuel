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
            title: "Which starting equation should we use?",
            detail: "This sets your starting calorie estimate. Your weigh-ins will show whether it fits.",
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
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.displayName)
                        .font(.circaEntryTitle)
                        .foregroundStyle(Color.circaInk)
                    Text(subtitle(for: option))
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.circaAccent : Color.circaInk3)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 68)
            .background(Color.circaCard, in: RoundedRectangle(cornerRadius: Circa.Radius.cardSmall))
            .overlay {
                RoundedRectangle(cornerRadius: Circa.Radius.cardSmall)
                    .strokeBorder(isSelected ? Color.circaAccent : Color.circaCardBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private func subtitle(for option: Gender) -> String {
        switch option {
        case .male: return "Male-based estimate"
        case .female: return "Female-based estimate"
        case .preferNotToSay: return "Uses a midpoint starting estimate"
        }
    }
}

#Preview {
    OnboardingGenderStepView(gender: .constant(.female), onNext: { print("")})
}
