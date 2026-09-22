import SwiftUI

struct OnboardingLoggingTipsStepView: View {
    let onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    private let mealExamples: [LoggingTipExample] = [
        .init(
            vagueLabel: "Without details",
            helpfulLabel: "With details",
            simpleTitle: "protein shake",
            refinedTitle: "1 scoop whey with 250 ml milk and 1 banana",
            simpleDetail: "The portion and liquid are unknown.",
            refinedDetail: "The ingredients and amounts are named.",
            simpleImageName: "shake_simple",
            refinedImageName: "shake_refined"
        ),
        .init(
            vagueLabel: "Without details",
            helpfulLabel: "With details",
            simpleTitle: "pasta",
            refinedTitle: "1 bowl chicken pasta with tomato sauce",
            simpleDetail: "The serving and sauce are unknown.",
            refinedDetail: "The bowl, protein and sauce are named.",
            simpleImageName: "pasta_simple",
            refinedImageName: "pasta_refined"
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
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }

            Button(action: onNext) {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(.circa(.primary, height: 52))
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.bottom, 16)
            .loggingTipEntrance(isVisible: hasAppeared, delay: 0.28, reduceMotion: reduceMotion)
        }
        .circaPaper()
        .onAppear {
            hasAppeared = false
            DispatchQueue.main.async {
                hasAppeared = true
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            CircaSectionLabel("How to write a meal")
            Text("A little detail helps.")
                .font(.circaTitle)
                .foregroundStyle(Color.circaInk)
            Text("Mention portions, ingredients and cooking style when you know them. Then review what Circa assumed.")
                .font(.circaBody)
                .foregroundStyle(Color.circaInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func examplesSection(title: String, symbol: String, examples: [LoggingTipExample]) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.circaRow)
                    .foregroundStyle(Color.circaAccent)
                    .frame(width: 34, height: 34)
                    .background(Color.circaWell, in: Circle())

                Text(title)
                    .font(.circaRow.weight(.semibold))
                    .foregroundStyle(Color.circaInk)

                Rectangle()
                    .fill(Color.circaRule)
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
    let simpleDetail: String
    let refinedDetail: String
    let simpleImageName: String
    let refinedImageName: String
}

private struct LoggingTipComparisonCard: View {
    let example: LoggingTipExample

    var body: some View {
        CircaCard {
            VStack(alignment: .leading, spacing: 12) {
                LoggingTipExampleSide(
                    label: example.vagueLabel,
                    title: example.simpleTitle,
                    detail: example.simpleDetail,
                    imageName: example.simpleImageName
                )
                CircaHairline(weight: .inCard)
                LoggingTipExampleSide(
                    label: example.helpfulLabel,
                    title: example.refinedTitle,
                    detail: example.refinedDetail,
                    imageName: example.refinedImageName
                )
            }
        }
    }
}

private struct LoggingTipExampleSide: View {
    let label: String
    let title: String
    let detail: String
    let imageName: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: Circa.Radius.thumb))
            VStack(alignment: .leading, spacing: 5) {
                CircaSectionLabel(label)
                Text(title)
                    .font(.circaEntryTitle)
                    .foregroundStyle(Color.circaInk)
                Text(detail)
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
