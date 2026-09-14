//
//  OnboardingPaceStepView.swift
//  GymFuel
//



import SwiftUI

struct OnboardingPaceStepView: View {
    let goal: GoalType
    let weightKg: Double
    @Binding var selectedPace: GoalPace?
    /// 1-based position in the flow, and the flow's length.
    let stepPosition: Int
    let stepCount: Int
    let onNext: () -> Void

    @AppStorage(BodyWeightUnit.preferenceKey)
    private var weightUnitRawValue = BodyWeightUnit.kilograms.rawValue

    @State private var choice: GoalPace = .steady

    private var unit: BodyWeightUnit {
        BodyWeightUnit(rawValue: weightUnitRawValue) ?? .kilograms
    }

    private var subtitle: String {
        switch goal {
        case .leanBulk:
            return "Pick how quickly you'd like to gain. Your calorie target follows the pace you pick."
        case .cut, .maintain:
            return "Pick how quickly you'd like to lose. Your calorie target follows the pace you pick."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            AdaptiveScrollContainer {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    VStack(spacing: 10) {
                        ForEach(GoalPace.options(for: goal), id: \.self) { row($0) }
                    }
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.top, 18)
                .padding(.bottom, 12)
            }

            footer
        }
        .circaPaper()
        .onAppear {
            choice = GoalPace.resolved(selectedPace, for: goal) ?? .steady
        }
    }

    // MARK: - Parts

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            CircaSectionLabel("Pace · \(stepPosition) of \(stepCount)")

            Text("How fast do you want to go?")
                .font(.circaTitle)
                .foregroundStyle(Color.circaInk)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.circaBody)
                .foregroundStyle(Color.circaInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ pace: GoalPace) -> some View {
        let isSelected = choice == pace
        let shape = RoundedRectangle(cornerRadius: Circa.Radius.card, style: .continuous)

        return Button {
            choice = pace
        } label: {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(pace.displayName)
                        .font(.circaEntryTitle)
                        .foregroundStyle(Color.circaInk)

                    Text(pace.aboutPerWeekText(for: goal, weightKg: weightKg, unit: unit))
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaInk2)
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(isSelected ? Color.circaInk : Color.circaInk3)
                    .accessibilityHidden(true)
            }
            .padding(Circa.Space.cardInset)
            .frame(maxWidth: .infinity, minHeight: Circa.minHitTarget, alignment: .leading)
            .background(Color.circaCard, in: shape)
            .overlay {
                shape.strokeBorder(
                    isSelected ? Color.circaInk : Color.circaCardBorder,
                    lineWidth: isSelected ? 1.5 : Circa.Rule.hairline
                )
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Text("A starting point.\nChange it any time in Settings.")
                .font(.circaMono)
                .foregroundStyle(Color.circaInk3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                selectedPace = choice
                onNext()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.circa(.primary, height: 52))
        }
        .padding(.horizontal, Circa.Space.screenMargin)
        .padding(.bottom, 16)
    }
}

#Preview("Pace · lose fat") {
    OnboardingPaceStepView(goal: .cut, weightKg: 80, selectedPace: .constant(nil), stepPosition: 11, stepCount: 14, onNext: {})
}

#Preview("Pace · gain · dark") {
    OnboardingPaceStepView(goal: .leanBulk, weightKg: 80, selectedPace: .constant(nil), stepPosition: 11, stepCount: 14, onNext: {})
        .preferredColorScheme(.dark)
}

#Preview("Pace · AX3") {
    OnboardingPaceStepView(goal: .cut, weightKg: 80, selectedPace: .constant(.faster), stepPosition: 11, stepCount: 14, onNext: {})
        .dynamicTypeSize(.accessibility3)
}
