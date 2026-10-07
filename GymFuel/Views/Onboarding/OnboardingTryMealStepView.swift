import SwiftUI

struct OnboardingTryMealStepView: View {
    @Binding var triedMeal: TriedMeal?
    let onNext: () -> Void

    @StateObject private var model: OnboardingTryMealViewModel

    private let examples = ["2 eggs, toast and tea", "rice with chicken stew", "a bowl of noodles with vegetables"]

    init(triedMeal: Binding<TriedMeal?>, onNext: @escaping () -> Void) {
        _triedMeal = triedMeal
        self.onNext = onNext
        _model = StateObject(wrappedValue: OnboardingTryMealViewModel(restoring: triedMeal.wrappedValue))
    }

    var body: some View {
        VStack(spacing: 0) {
            AdaptiveScrollContainer {
                VStack(alignment: .leading, spacing: 20) {
                    switch model.phase {
                    case .typing: typing
                    case .working: working
                    case .result(let meal): result(meal)
                    case .example(let afterFailure): example(afterFailure: afterFailure)
                    }
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.top, 18)
                .padding(.bottom, 20)
            }

            primaryButton
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.bottom, 16)
        }
        .circaPaper()
        .onChange(of: model.phase) { triedMeal = model.triedMeal }
    }

    private var typing: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                CircaSectionLabel("In your own words")
                Text("Tell us a meal you often eat.")
                    .font(.circaTitle)
                    .foregroundStyle(Color.circaInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Say it the way you'd tell a friend.")
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TextField("Your meal", text: $model.text, prompt: Text("Your meal").foregroundStyle(Color.circaInk3), axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(.title2).weight(.medium))
                .foregroundStyle(Color.circaInk)
                .tint(Color.circaAccent)
                .lineLimit(2...)
                .submitLabel(.done)
                .accessibilityLabel("Describe a meal you often eat")

            if model.foundNoMeal {
                Text("Circa couldn't find a meal in that. Try naming what's on the plate.")
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                CircaSectionLabel("Or tap one")
                ForEach(examples, id: \.self) { example in
                    Button(example) { model.text = example }
                        .buttonStyle(.circa(.secondary, height: Circa.minHitTarget))
                }
            }
        }
    }

    private var working: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProgressView()
                .tint(Color.circaAccent)
            Text("Reading “\(model.text.trimmingCharacters(in: .whitespacesAndNewlines))”…")
                .font(.circaTitle)
                .foregroundStyle(Color.circaInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func result(_ meal: TriedMeal) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                CircaSectionLabel(meal.title)
                Text("Circa's first guess. Anything different?")
                    .font(.circaTitle)
                    .foregroundStyle(Color.circaInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let assumption = MealBreakdownCalculator().assumptions(of: meal.feedback).first {
                CircaCard(.sunken) {
                    VStack(alignment: .leading, spacing: 6) {
                        CircaSectionLabel("Biggest assumption")
                        Text(assumption)
                            .font(.circaBody)
                            .foregroundStyle(Color.circaAccent)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if let breakdown = meal.feedback.breakdown {
                MealBreakdownCard(breakdown: breakdown)
            }
        }
    }

    private func example(afterFailure: Bool) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(afterFailure ? "We couldn't reach Circa just now. Here's an example." : "Here's an example.")
                .font(.circaBody)
                .foregroundStyle(Color.circaInk2)
                .fixedSize(horizontal: false, vertical: true)

            CircaCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Image("eggs_toast_coffee")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: Circa.Radius.thumb))
                        VStack(alignment: .leading, spacing: 6) {
                            Text("One egg, toast and coffee")
                                .font(.circaEntryTitle)
                                .fixedSize(horizontal: false, vertical: true)
                            CircaEstimate("240 kcal", certainty: .estimated)
                            Text("Example estimate")
                                .font(.circaMono)
                                .foregroundStyle(Color.circaInk3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    CircaHairline(weight: .inCard)
                    CircaSectionLabel("Circa's assumptions")
                    Text("One egg, two slices of toast and a cup of coffee. Check the amounts and change anything that differs from your breakfast.")
                        .font(.circaBody)
                        .foregroundStyle(Color.circaInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder
    private var primaryButton: some View {
        if model.phase == .typing {
            VStack(spacing: 4) {
                Button { model.submit() } label: {
                    Label("Estimate this", systemImage: "sparkles").frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary, height: 52))
                .disabled(!model.canSubmit)
                .opacity(model.canSubmit ? 1 : 0.45)

                Button("Show me an example instead") { model.showExample() }
                    .buttonStyle(.circa(.quiet))
            }
        } else {
            Button(action: onNext) {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(.circa(.primary, height: 52))
            .disabled(!model.canContinue)
            .opacity(model.canContinue ? 1 : 0.45)
        }
    }
}

#Preview {
    OnboardingTryMealStepView(triedMeal: .constant(nil), onNext: {})
}
