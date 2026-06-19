import SwiftUI

struct OnboardingSummaryStepView: View {
    let name: String
    let gender: Gender
    let age: Int
    let heightCm: Double
    let weightKg: Double
    let goalType: GoalType
    let activityLevel: NonTrainingActivityLevel
    let onStartTracking: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var hasAppeared = false

    private var targetMacros: Macros {
        let profile = UserProfile(
            id: "onboarding-summary",
            name: name,
            heightCm: heightCm,
            age: age,
            weightKg: weightKg,
            goalType: goalType,
            nonTrainingActivityLevel: activityLevel,
            isOnboardingComplete: false,
            gender: gender
        )
        return MacroTargetCalculator().targetMacros(for: profile) ?? .zero
    }

    var body: some View {
        VStack(spacing: 12) {
            Image("summary")
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 240)
                .padding(.top, 8)
                .onboardingSummaryAppearance(isVisible: hasAppeared, order: 0)

            VStack(spacing: 8) {
                Text("Your nutrition targets are ready")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("Built around your goal, training, and daily activity.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .onboardingSummaryAppearance(isVisible: hasAppeared, order: 1)

            VStack(spacing: 0) {
                goalSummaryRow(title: "Goal", value: goalType.displayName, tint: .fuelOrange)
                summaryDivider
                summaryRow(emoji: "🔥", title: "Calories", value: "\(Int(targetMacros.calories)) kcal", tint: .fuelOrange)
                summaryDivider
                summaryRow(emoji: "💪", title: "Protein", value: "\(Int(targetMacros.protein)) g", tint: .fuelBlue)
                summaryDivider
                summaryRow(emoji: "⚡", title: "Carbs", value: "\(Int(targetMacros.carbs)) g", tint: .fuelGreen)
                summaryDivider
                summaryRow(emoji: "🥑", title: "Fat", value: "\(Int(targetMacros.fat)) g", tint: .fuelRed)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .onboardingSummaryAppearance(isVisible: hasAppeared, order: 2)


            Spacer()

            Button(action: onStartTracking) {
                Text("Start Tracking")
                    .font(.headline.bold())
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.black, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .onboardingSummaryAppearance(isVisible: hasAppeared, order: 3)
        }
        .padding()
        .onAppear {
            hasAppeared = true
        }
    }

    private var summaryDivider: some View {
        Divider()
            .padding(.leading, 50)
            .padding(.vertical, 10)
    }

    private func goalSummaryRow(title: String, value: String, tint: Color) -> some View {
        summaryRowContent(title: title, value: value) {
            Image(systemName: goalType.symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.primary)
                .frame(width: 38, height: 38)
                .background(Color(.systemBackground), in: Circle())
                .overlay {
                    Circle()
                        .stroke(tint.opacity(colorScheme == .dark ? 0.24 : 0.16), lineWidth: 1)
                }
        }
    }

    private func summaryRow(emoji: String, title: String, value: String, tint: Color) -> some View {
        summaryRowContent(title: title, value: value) {
            Text(emoji)
                .font(.title3)
                .frame(width: 38, height: 38)
                .background(tint.opacity(colorScheme == .dark ? 0.22 : 0.12), in: Circle())
        }
    }

    private func summaryRowContent<Icon: View>(title: String, value: String, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 12) {
            icon()

            Text(title)
                .font(.subheadline.weight(.semibold))

            Spacer()

            Text(value)
                .font(.headline.weight(.bold))
                .lineLimit(1)
        }
    }
}

private extension View {
    func onboardingSummaryAppearance(isVisible: Bool, order: Int) -> some View {
        opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 18)
            .animation(
                .spring(response: 0.64, dampingFraction: 0.9).delay(Double(order) * 0.22),
                value: isVisible
            )
    }
}

#Preview {
    OnboardingSummaryStepView(
        name: "Ahmad",
        gender: .male,
        age: 28,
        heightCm: 178,
        weightKg: 82,
        goalType: .leanBulk,
        activityLevel: .somewhatActive,
        onStartTracking: {}
    )
}

