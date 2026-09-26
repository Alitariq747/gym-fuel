//
//  OnboardingSummaryStepView.swift
//  GymFuel
//
//  Step 4f — the plan screen, the last onboarding step: where the plan
//  heads, roughly when, and one reason for each number. `Onboarding · your
//  numbers` on the canvas, with the words from design.md's Canvas drift table.
//  Built from the 2a kit. Nothing here works a number out: it shows what
//  `plannedProfile` will save after authentication.
//

import SwiftUI

struct OnboardingSummaryStepView: View {
    let answers: OnboardingAnswers
    /// Hands back the numbers edited here, or nil to keep the worked-out ones.
    let onStartTracking: (Macros?) -> Void

    /// Shared with the weight steps, so a pounds user reads pounds here too.
    @AppStorage(BodyWeightUnit.preferenceKey) private var unitRawValue = BodyWeightUnit.kilograms.rawValue
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Lives only as long as this screen: going back to change an answer works
    /// the numbers out again, as changing goal, goal weight or activity does.
    @State private var editedTargets: Macros?
    @State private var isEditing = false
    @State private var isShowingSources = false

    private let calculator = MacroTargetCalculator()

    private var unit: BodyWeightUnit {
        BodyWeightUnit(rawValue: unitRawValue) ?? .kilograms
    }

    /// Right-aligned numbers beside wrapping words break at accessibility sizes,
    /// so every row here goes vertical there — `design.md` rule 8.
    private var isStacked: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    /// What account creation will save, with any edit made here. Nil only while an answer
    /// is missing, which the flow never allows this far.
    private var planned: UserProfile? {
        var shown = answers
        shown.editedTargets = editedTargets
        return shown.plannedProfile(id: "onboarding-plan", on: .now, using: calculator)
    }

    var body: some View {
        let profile = planned
        let line = profile.flatMap { WeightPlan(profile: $0) }

        VStack(spacing: 0) {
            AdaptiveScrollContainer {
                VStack(alignment: .leading, spacing: 22) {
                    header(line)

                    if let profile {
                        if let line { chart(line) }
                        plan(profile)
                    }
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.top, 18)
                .padding(.bottom, 12)
            }

            Button {
                onStartTracking(editedTargets)
            } label: {
                Text("Save my progress").frame(maxWidth: .infinity)
            }
            .buttonStyle(.circa(.primary, height: 52))
            .disabled(profile == nil)
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.bottom, 16)
        }
        .circaPaper()
        // The targets screen's editor: it knows nothing about profiles, so it works
        // here before anything is saved.
        .sheet(isPresented: $isEditing) {
            if let profile = planned,
               let targets = profile.savedTargets,
               let basis = calculator.basis(for: profile) {
                TargetsEditorSheet(
                    targets: targets,
                    gender: answers.gender,
                    basisKg: basis.kg,
                    goal: profile.goalType ?? .defaultValue
                ) { editedTargets = $0 }
            }
        }
        .sheet(isPresented: $isShowingSources) {
            NutritionSourcesView()
        }
    }

    // MARK: - Parts

    private func header(_ line: WeightPlan?) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            CircaSectionLabel("Your plan")

            Text("Here's where you begin.")
                .font(.circaTitle)
                .foregroundStyle(Color.circaInk)
                .fixedSize(horizontal: false, vertical: true)

            if let line {
                Text(PlanCopy.headline(for: line, unit: unit))
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The Weight screen's chart: today's weight as the first dot, and the dotted
    /// line from it to the goal date. An edit never moves it — the line comes
    /// from the pace, not the target (decided 19 September).
    private func chart(_ line: WeightPlan) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        // A line with no goal date gets the four weeks the Weight screen shows.
        let end = line.goalDate
            ?? calendar.date(byAdding: .day, value: WeightViewModel.lookaheadDays, to: today)
            ?? today

        return CircaCard {
            WeightChart(
                series: WeightTrendCalculator().series(from: [WeighIn(weightKg: line.startWeightKg)]),
                unit: unit,
                domain: today...max(end, today),
                plan: line
            )
        }
    }

    /// The targets, Edit, then the working behind them. Only the estimate is
    /// dotted — a target is set, not guessed (`design.md` rule 1).
    @ViewBuilder
    private func plan(_ profile: UserProfile) -> some View {
        if let targets = profile.savedTargets,
           let maintenance = profile.maintenanceCalories,
           let workedOut = calculator.targetMacros(for: profile),
           let reasons = PlanCopy.reasons(for: profile, workedOut: workedOut, unit: unit, calculator: calculator) {
            CircaCard {
                VStack(alignment: .leading, spacing: Circa.Space.rowGap) {
                    CircaSectionLabel("Your daily targets")
                    row("Calories", targets.calories, suffix: "kcal", font: .circaMonoLarge)
                    CircaHairline(weight: .inCard)
                    row("Protein", targets.protein, suffix: "g")
                    CircaHairline(weight: .inCard)
                    row("Carbs", targets.carbs, suffix: "g")
                    CircaHairline(weight: .inCard)
                    row("Fat", targets.fat, suffix: "g")
                }
            }

            editLink

            CircaCard {
                VStack(alignment: .leading, spacing: Circa.Space.rowGap) {
                    CircaSectionLabel("How we got \(targets.calories.formatted(.number.precision(.fractionLength(0))))")
                    step(TargetsCopy.maintenanceLabel) {
                        Text(TargetsCopy.maintenancePrefix)
                            .font(.circaBody)
                            .foregroundStyle(Color.circaInk2)
                        CircaEstimate(TargetsCopy.maintenanceValue(maintenance), certainty: .estimated)
                    }
                    if let calories = reasons.calories {
                        step(calories.reason) { Text(calories.amount) }
                    }
                    CircaHairline(weight: .inCard)
                    row("Your daily target", targets.calories, suffix: "kcal")
                    CircaHairline(weight: .inCard)
                    macroReasons(reasons)
                    CircaHairline(weight: .inCard)
                    sourcesLink
                }
            }
        }
    }

    private var editLink: some View {
        Button {
            isEditing = true
        } label: {
            Label("Edit numbers", systemImage: "slider.horizontal.3")
        }
        .buttonStyle(.circa(.link))
        .frame(maxWidth: .infinity)
    }

    private var sourcesLink: some View {
        Button {
            isShowingSources = true
        } label: {
            HStack(spacing: 7) {
                Text("How these were worked out")
                Image(systemName: "chevron.forward")
                    .font(.circaCaption.weight(.semibold))
            }
        }
        .buttonStyle(.circa(.link))
        .padding(.leading, -10)
    }

    // MARK: - Shapes

    /// A target and its number.
    private func row(_ title: String, _ value: Double, suffix: String, font: Font = .circaMonoValue) -> some View {
        adaptive {
            Text(title)
                .font(.circaRow)
                .foregroundStyle(Color.circaInk)
            if !isStacked { Spacer(minLength: Circa.Space.rowGap) }
            amount(value, suffix: suffix, font: font)
        }
        .accessibilityElement(children: .combine)
    }

    /// A line of the calorie sum: quieter than the target it adds up to.
    private func step<Value: View>(_ title: String, @ViewBuilder value: () -> Value) -> some View {
        adaptive {
            Text(title)
                .font(.circaBody)
                .foregroundStyle(Color.circaInk2)
            if !isStacked { Spacer(minLength: Circa.Space.rowGap) }
            HStack(alignment: .firstTextBaseline, spacing: 4) { value() }
                .font(.circaMonoValue)
                .monospacedDigit()
                .foregroundStyle(Color.circaInk)
        }
        .accessibilityElement(children: .combine)
    }

    /// Protein, carbs and fat, each named before the line that says why. One
    /// wrapping text per line, so nothing needs to go vertical at AX sizes.
    private func macroReasons(_ reasons: PlanCopy.Reasons) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach([("Protein", reasons.protein), ("Carbs", reasons.carbs), ("Fat", reasons.fat)], id: \.0) { title, text in
                Text("\(Text(title).fontWeight(.semibold).foregroundStyle(Color.circaInk)) \(text)")
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// A whole number with its unit beside it, quieter, as on the artboard.
    private func amount(_ value: Double, suffix: String, font: Font) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value.formatted(.number.precision(.fractionLength(0))))
                .font(font)
                .monospacedDigit()
                .foregroundStyle(Color.circaInk)
            Text(suffix)
                .font(.circaMono)
                .foregroundStyle(Color.circaInk3)
        }
    }

    /// A row that is horizontal normally and vertical at accessibility sizes,
    /// without writing its contents twice.
    private func adaptive<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let layout = isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 6))
        return layout(content)
    }
}

#if DEBUG
#Preview("Plan · Lose fat") {
    OnboardingSummaryStepView(
        answers: OnboardingAnswers(gender: .male, age: 35, heightCm: 178, weightKg: 85, goalType: .cut, activityLevel: .mostlySitting, goalWeightKg: 75),
        onStartTracking: { _ in }
    )
}

#Preview("Plan · Maintain · dark") {
    OnboardingSummaryStepView(
        answers: OnboardingAnswers(gender: .female, age: 30, heightCm: 165, weightKg: 60, goalType: .maintain, activityLevel: .lightlyActive),
        onStartTracking: { _ in }
    )
    .preferredColorScheme(.dark)
}
#endif
