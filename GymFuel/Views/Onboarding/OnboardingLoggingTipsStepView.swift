import SwiftUI

struct OnboardingLoggingTipsStepView: View {
    let onNext: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    private let mealExamples: [LoggingTipExample] = [
        .init(
            vagueLabel: "Too vague",
            helpfulLabel: "More helpful",
            simpleTitle: "protein shake",
            refinedTitle: "1 scoop whey with 250 ml milk and 1 banana",
            simpleConfidence: 33,
            refinedConfidence: 88,
            simpleCalories: 180,
            refinedCalories: 360,
            simpleImageName: "shake_simple",
            refinedImageName: "shake_refined"
        ),
        .init(
            vagueLabel: "Too vague",
            helpfulLabel: "More helpful",
            simpleTitle: "pasta",
            refinedTitle: "1 bowl chicken pasta with tomato sauce",
            simpleConfidence: 38,
            refinedConfidence: 87,
            simpleCalories: 320,
            refinedCalories: 520,
            simpleImageName: "pasta_simple",
            refinedImageName: "pasta_refined"
        )
    ]

    private let workoutExamples: [LoggingTipExample] = [
        .init(
            vagueLabel: "Too vague",
            helpfulLabel: "More helpful",
            simpleTitle: "leg day",
            refinedTitle: "Leg day, 70 min, high intensity, 22 total sets",
            simpleConfidence: 35,
            refinedConfidence: 89,
            simpleCalories: 210,
            refinedCalories: 520,
            simpleImageName: "leg_day_simple",
            refinedImageName: "leg_day_refined"
        ),
        .init(
            vagueLabel: "Too vague",
            helpfulLabel: "More helpful",
            simpleTitle: "walk",
            refinedTitle: "Incline treadmill walk, 25 min, moderate intensity",
            simpleConfidence: 40,
            refinedConfidence: 86,
            simpleCalories: 120,
            refinedCalories: 230,
            simpleImageName: "walk_simple",
            refinedImageName: "walk_refined"
        )
    ]

    var body: some View {
        VStack(spacing: 14) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                        .loggingTipEntrance(isVisible: hasAppeared, delay: 0, reduceMotion: reduceMotion)

                    examplesSection(title: "Meals", symbol: "fork.knife", examples: mealExamples)
                        .loggingTipEntrance(isVisible: hasAppeared, delay: 0.14, reduceMotion: reduceMotion)

                    examplesSection(title: "Workouts", symbol: "dumbbell.fill", examples: workoutExamples)
                        .loggingTipEntrance(isVisible: hasAppeared, delay: 0.28, reduceMotion: reduceMotion)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }

            Button(action: onNext) {
                HStack(spacing: 10) {
                    Text("Continue")
                        .font(.headline.bold())
                    Image(systemName: "arrow.right")
                        .font(.headline.weight(.bold))
                }
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)
                .background(
                    LinearGradient(
                        colors: [Color.fuelBlue, Color.fuelBlue.opacity(0.82)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .shadow(color: Color.fuelBlue.opacity(colorScheme == .dark ? 0 : 0.25), radius: 16, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
            .loggingTipEntrance(isVisible: hasAppeared, delay: 0.42, reduceMotion: reduceMotion)
        }
        .onAppear {
            hasAppeared = false
            DispatchQueue.main.async {
                hasAppeared = true
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Text("Quick tip")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.fuelBlue)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(Color.fuelBlue.opacity(0.13), in: Capsule())

            VStack(spacing: 2) {
                (Text("Better ") + Text("details.").foregroundStyle(Color.fuelBlue))
                (Text("Better ") + Text("estimates.").foregroundStyle(Color.fuelBlue))
            }
            .font(.system(size: 34, weight: .black, design: .rounded))
            .multilineTextAlignment(.center)
            .lineSpacing(-2)
            .minimumScaleFactor(0.8)

            Text("Add portions, brands, cooking style, duration, intensity, and sets so LiftEats can judge meals and workouts more accurately.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity)
    }

    private func examplesSection(title: String, symbol: String, examples: [LoggingTipExample]) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.fuelBlue, in: Circle())

                Text(title)
                    .font(.title3.weight(.bold))

                Rectangle()
                    .fill(Color(.separator).opacity(0.45))
                    .frame(height: 1)
            }

            VStack(spacing: 10) {
                ForEach(examples) { example in
                    LoggingTipComparisonCard(example: example)
                }
            }
        }
    }
}

private struct LoggingTipExample: Identifiable {
    let id = UUID()
    let vagueLabel: String
    let helpfulLabel: String
    let simpleTitle: String
    let refinedTitle: String
    let simpleConfidence: Int
    let refinedConfidence: Int
    let simpleCalories: Int
    let refinedCalories: Int
    let simpleImageName: String
    let refinedImageName: String
}

private struct LoggingTipComparisonCard: View {
    let example: LoggingTipExample

    var body: some View {
        ZStack {
            HStack(alignment: .top, spacing: 0) {
                LoggingTipExampleSide(
                    label: example.vagueLabel,
                    labelTone: .fuelOrange,
                    title: example.simpleTitle,
                    confidence: example.simpleConfidence,
                    calories: example.simpleCalories,
                    imageName: example.simpleImageName,
                    isHelpful: false
                )

                Rectangle()
                    .fill(Color.fuelGreen.opacity(0.18))
                    .frame(width: 1)

                LoggingTipExampleSide(
                    label: example.helpfulLabel,
                    labelTone: .fuelGreen,
                    title: example.refinedTitle,
                    confidence: example.refinedConfidence,
                    calories: example.refinedCalories,
                    imageName: example.refinedImageName,
                    isHelpful: true
                )
            }

            Image(systemName: "arrow.right")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.fuelBlue)
                .frame(width: 42, height: 42)
                .background(Color(.systemBackground), in: Circle())
                .overlay {
                    Circle()
                        .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.separator).opacity(0.28), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.07), radius: 14, y: 6)
    }
}

private struct LoggingTipExampleSide: View {
    let label: String
    let labelTone: Color
    let title: String
    let confidence: Int
    let calories: Int
    let imageName: String
    let isHelpful: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(labelTone)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(labelTone.opacity(0.12), in: Capsule())

            HStack(alignment: .center, spacing: 8) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .padding(6)
                    .background(labelTone.opacity(isHelpful ? 0.12 : 0.10), in: Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Confidence")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(labelTone)
                        Text("\(confidence)%")
                            .font(.title3.weight(.black))
                            .foregroundStyle(labelTone)
                    }

                    Divider()

                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.fuelOrange)
                        Text("\(calories) cal")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 136, alignment: .topLeading)
        .background(isHelpful ? Color.fuelGreen.opacity(0.045) : Color.clear)
    }
}

private extension View {
    func loggingTipEntrance(isVisible: Bool, delay: Double, reduceMotion: Bool) -> some View {
        opacity(isVisible ? 1 : 0)
            .offset(y: reduceMotion || isVisible ? 0 : 18)
            .animation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.88).delay(delay), value: isVisible)
    }
}

#Preview {
    OnboardingLoggingTipsStepView(onNext: {})
}
