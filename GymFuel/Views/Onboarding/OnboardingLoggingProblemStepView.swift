import SwiftUI

struct OnboardingLoggingProblemStepView: View {
    @Binding var problem: LoggingProblem?
    let onNext: () -> Void

    var body: some View {
        OnboardingMetricPage(
            title: "What makes logging food hard for you?",
            canContinue: problem != nil,
            onContinue: onNext
        ) {
            VStack(spacing: 12) {
                ForEach(LoggingProblem.allCases, id: \.self) { option in
                    problemOption(option)
                }
            }
        }
    }

    private func problemOption(_ option: LoggingProblem) -> some View {
        let isSelected = problem == option

        return Button {
            problem = option
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Text(option.title)
                    .font(.circaEntryTitle)
                    .foregroundStyle(Color.circaInk)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

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
    OnboardingLoggingProblemStepView(problem: .constant(nil), onNext: {})
}
