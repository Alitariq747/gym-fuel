import SwiftUI

struct OnboardingTryMealStepView: View {
    @Binding var triedMeal: TriedMeal?
    let problem: LoggingProblem?
    let onNext: () -> Void

    @StateObject private var model: OnboardingTryMealViewModel
    @State private var showEditor = false
    @FocusState private var isWriting: Bool

    private let examples = ["2 eggs, toast and tea", "rice with chicken stew", "a bowl of noodles with vegetables"]

    init(triedMeal: Binding<TriedMeal?>, problem: LoggingProblem?, onNext: @escaping () -> Void) {
        _triedMeal = triedMeal
        self.problem = problem
        self.onNext = onNext
        _model = StateObject(wrappedValue: OnboardingTryMealViewModel(restoring: triedMeal.wrappedValue))
    }

    var body: some View {
        VStack(spacing: 0) {
            AdaptiveScrollContainer {
                VStack(alignment: .leading, spacing: 20) {
                    switch model.phase {
                    case .typing: typing
                    case .working, .result: estimate
                    case .example(let afterFailure): example(afterFailure: afterFailure)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: model.phase)
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
        .sheet(isPresented: $showEditor) {
            if let breakdown = model.triedMeal?.feedback.breakdown {
                MealBreakdownEditorSheet(breakdown: breakdown) { model.correct(to: $0) }
            }
        }
    }

    private var typing: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                CircaSectionLabel("In your own words")
                Text("Tell us a meal you often eat.")
                    .font(.circaTitle)
                    .foregroundStyle(Color.circaInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text(problem?.tryMealDetail ?? LoggingProblem.defaultTryMealDetail)
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TryMealField(text: $model.text, isFocused: $isWriting)

            if model.foundNoMeal {
                Text("Circa couldn't find a meal in that. Try naming what's on the plate.")
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TryMealExamples(examples: examples) { model.text = $0 }
        }
    }

    /// Waiting and answered are one view, so the title and the card keep their
    /// place and the numbers land on the rules already drawn.
    private var estimate: some View {
        let meal = model.triedMeal
        let total = meal?.feedback.breakdown.map { MealBreakdownCalculator().total(of: $0) }

        return VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                CircaSectionLabel("Your words")
                Text(verbatim: meal?.words ?? model.text.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.circaInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let correction = model.correction {
                DetailMacroSummaryCard(macros: total, certainty: .estimated) {
                    TryMealChangeHeader(correction: correction)
                }
            } else {
                DetailMacroSummaryCard(macros: total, certainty: .estimated)
            }

            if let meal {
                result(meal)
            } else {
                TryMealPendingBreakdown()
            }
        }
    }

    private func result(_ meal: TriedMeal) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            if model.correction == nil {
                TryMealAssumptionCard(assumption: MealBreakdownCalculator().assumptions(of: meal.feedback).first) {
                    showEditor = true
                }
            }

            if let breakdown = meal.feedback.breakdown {
                MealBreakdownCard(breakdown: breakdown) { showEditor = true }
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

                if !isWriting {
                    Button("Show me an example instead") { model.showExample() }
                        .buttonStyle(.circa(.quiet))
                }
            }
        } else {
            VStack(spacing: 10) {
                if model.phase == .working {
                    Text("This takes a few seconds.")
                        .font(.circaMono)
                        .foregroundStyle(Color.circaInk3)
                }

                Button(action: onNext) {
                    Text(model.correction == nil ? "Continue" : "Let's find your targets").frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary, height: 52))
                .disabled(!model.canContinue)
                .opacity(model.canContinue ? 1 : 0.45)
            }
        }
    }
}

#Preview {
    OnboardingTryMealStepView(triedMeal: .constant(nil), problem: .notInDatabase, onNext: {})
}
