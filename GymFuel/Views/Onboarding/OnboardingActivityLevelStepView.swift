//
//  OnboardingActivityLevelStepView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 11/12/2025.
//

import SwiftUI

/// Step: What does a normal week look like, including exercise?
struct OnboardingActivityLevelStepView: View {
    @Binding var selectedLevel: ActivityLevel?
    let onNext: () -> Void

    @State private var tempSelection: ActivityLevel = .mostlySitting

    var body: some View {
        OnboardingMetricPage(
            title: "What does a normal week look like?",
            detail: "Include work, walking and any exercise. Choose the closest match, not your busiest day.",
            onContinue: handleNext
        ) {
            VStack(spacing: 12) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    activityOption(level)
                }
            }
        }
        .onAppear {
            if let existing = selectedLevel {
                tempSelection = existing
            }
        }
    }

    private func activityOption(_ level: ActivityLevel) -> some View {
        let isSelected = tempSelection == level

        return Button {
            tempSelection = level
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(.circaEntryTitle)
                        .foregroundStyle(Color.circaInk)
                    Text(level.detail)
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

    private func handleNext() {
        selectedLevel = tempSelection
        onNext()
    }
}


#Preview {
    OnboardingActivityLevelStepView(selectedLevel: .constant(.veryActive), onNext: { print("") })
}
