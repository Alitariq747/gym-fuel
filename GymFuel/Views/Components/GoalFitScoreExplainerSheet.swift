import SwiftUI

struct GoalFitScoreExplainerSheet: View {
    var primaryButtonTitle: String = "Done"
    var onPrimaryAction: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let factors: [GoalFitScoreFactor] = [
        GoalFitScoreFactor(
            id: "muscleSupport",
            emoji: "🍗",
            title: "Useful protein",
            subtitle: "Meals with more useful protein usually score better.",
            tint: .fuelGreen
        ),
        GoalFitScoreFactor(
            id: "proteinEfficiency",
            emoji: "🎯",
            title: "Protein efficiency",
            subtitle: "Protein should not come with too many extra calories.",
            tint: .fuelBlue
        ),
        GoalFitScoreFactor(
            id: "energyFit",
            emoji: "🔥",
            title: "Goal calories",
            subtitle: "Calories should make sense for your goal.",
            tint: .fuelOrange
        ),
        GoalFitScoreFactor(
            id: "macroDominance",
            emoji: "🥧",
            title: "Macro balance",
            subtitle: "We look at the balance of protein, carbs, and fats.",
            tint: .purple
        ),
        GoalFitScoreFactor(
            id: "goalPracticality",
            emoji: "✓",
            title: "Practicality",
            subtitle: "We reward meals that are easier to repeat consistently.",
            tint: .cyan
        )
    ]

    private var background: Color {
        colorScheme == .dark ? Color.black : Color(.systemBackground)
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground).opacity(0.82) : Color(.systemBackground)
    }

    private var cardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(.quaternaryLabel)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    scoreHero
                    factorList
                    scoringGuardrail
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 22)
            }

            primaryButton
        }
        .background(background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image("LiftEatsWelcomeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 36)

            VStack(spacing: 6) {
                Text("What matters most")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("Your score looks at the nutrition patterns that actually matter.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    private var scoreHero: some View {
        HStack(spacing: 14) {
            ScorePreviewRing(score: 78, tint: .fuelOrange)
                .frame(width: 92, height: 92)
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(cardStroke)
                .frame(width: 1, height: 64)

            VStack(spacing: 7) {
                Text("🛡️")
                    .font(.system(size: 26))
                Text("A premium score\nis earned, not inflated.")
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .frame(maxWidth: 330)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.fuelOrange.opacity(colorScheme == .dark ? 0.45 : 0.22), lineWidth: 1)
        )
        .shadow(color: Color.fuelOrange.opacity(colorScheme == .dark ? 0.18 : 0.10), radius: 20, y: 10)
    }

    private var factorList: some View {
        VStack(spacing: 6) {
            ForEach(factors) { factor in
                GoalFitFactorRow(factor: factor)
            }
        }
    }

    private var scoringGuardrail: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("⚖️")
                .font(.system(size: 18))
                .frame(width: 34, height: 34)
                .background(Color(.tertiarySystemFill), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Final score")
                    .font(.subheadline.weight(.semibold))
                Text("LiftEats combines these factors with goal-specific weights, adjusts for confidence, then applies hard ceilings for extreme calories, low protein efficiency, or very high fat.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(cardStroke, lineWidth: 1))
    }

    private var primaryButton: some View {
        Button {
            if let onPrimaryAction {
                onPrimaryAction()
            } else {
                dismiss()
            }
        } label: {
            Text(primaryButtonTitle)
                .font(.headline.bold())
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.98, green: 0.80, blue: 0.43), Color(red: 0.82, green: 0.56, blue: 0.20)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }
}

private struct GoalFitScoreFactor: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let subtitle: String
    let tint: Color
}

private struct GoalFitFactorRow: View {
    let factor: GoalFitScoreFactor

    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground).opacity(0.82) : Color(.systemBackground)
    }

    private var cardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(.quaternaryLabel)
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(factor.emoji)
                .font(.system(size: 21))
                .frame(width: 48, height: 48)
                .background(factor.tint.opacity(colorScheme == .dark ? 0.18 : 0.12), in: Circle())
                .overlay(Circle().stroke(factor.tint.opacity(0.24), lineWidth: 1))

            VStack(alignment: .leading, spacing: 1) {
                Text(factor.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(factor.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineSpacing(0)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(cardStroke, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

private struct ScorePreviewRing: View {
    let score: Int
    let tint: Color

    private var progress: Double {
        min(max(Double(score) / 100, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.tertiarySystemFill), lineWidth: 7)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 1) {
                Text("\(score)")
                    .font(.system(size: 30, weight: .bold))
                Text("Goal Fit")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(tint)
            }
        }
        .foregroundStyle(.primary)
        .shadow(color: tint.opacity(0.18), radius: 14, y: 6)
        .accessibilityLabel("Goal fit score example, \(score)")
    }
}

#Preview {
    GoalFitScoreExplainerSheet(primaryButtonTitle: "Next")
}
