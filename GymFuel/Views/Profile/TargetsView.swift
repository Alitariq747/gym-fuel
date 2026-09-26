//
//  TargetsView.swift
//  GymFuel
//

import SwiftUI

/// The one place the user's numbers and their goal live. Opens from Settings
/// until 7 puts it in the menu.
///
/// **Nothing here works a target out.** It reads what was saved, because a screen
/// that recalculates on appear is a screen that moves targets without the user
/// asking — `build-order.md` Step 4, *The rules*.
///
/// Part A of Step 4d is read-only: Edit and Recalculate arrive in Part B, and the
/// goal, goal weight and activity pickers in Part C.
struct TargetsView: View {
    @EnvironmentObject private var profileVm: UserProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Shared with the weigh-in sheet and the goal weight step, so a pounds user
    /// reads "Set at 183 lbs" here too.
    @AppStorage(BodyWeightUnit.preferenceKey) private var unitRawValue = BodyWeightUnit.kilograms.rawValue
    /// Stateless, and the view model keeps its own private one — this is for the
    /// protein and fat basis the editor needs, nothing else.
    private let calculator = MacroTargetCalculator()
    @State private var isEditingTargets = false
    @State private var isConfirmingRecalculate = false
    @State private var planSheet: PlanSheet?
    /// A goal chosen but not yet saved: Gain and Lose fat need a goal weight first.
    @State private var pendingGoal: GoalType?
    /// The wheel's row, in whole units of `unit`. Nil until the wheel moves.
    @State private var selectedGoalWeight: Int?

    private enum PlanSheet: String, Identifiable {
        /// The goal and the goal weight it needs — one sheet, two stages.
        case goalAndGoalWeight
        case activity

        var id: String { rawValue }
    }

    private var unit: BodyWeightUnit {
        BodyWeightUnit(rawValue: unitRawValue) ?? .kilograms
    }

    /// Right-aligned mono numbers beside wrapping words is the Dynamic Type break
    /// `design.md` rule 8 names, so every row here goes vertical at AX sizes.
    private var isStacked: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 14) {
                header

                if let profile = profileVm.profile, let targets = profile.savedTargets {
                    numbersCard(targets, profile: profile)
                    if let maintenance = profile.maintenanceCalories {
                        estimateCard(maintenance)
                    }
                    planCard(profile)
                    actions

                    if let message = profileVm.errorMessage {
                        Text(message)
                            .font(.circaCaption)
                            .foregroundStyle(Color.circaDanger)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text("Your targets appear here once your profile is set up.")
                        .font(.circaBody)
                        .foregroundStyle(Color.circaInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.vertical, 18)
        }
        .circaPaper()
        .sheet(isPresented: $isEditingTargets) {
            if let profile = profileVm.profile,
               let targets = profile.savedTargets,
               let basis = calculator.basis(for: profile) {
                TargetsEditorSheet(
                    targets: targets,
                    gender: profile.gender,
                    basisKg: basis.kg,
                    // The same default `basis(for:)` uses, or the basis weight and
                    // the grams per kg would come from different goals.
                    goal: profile.goalType ?? .defaultValue
                ) { macros in
                    Task { await profileVm.saveEditedTargets(macros) }
                }
            }
        }
        // Recalculate replaces numbers the user may have typed, so it asks. The
        // app changing a target without being asked is the failure this avoids.
        .alert("Recalculate your targets?", isPresented: $isConfirmingRecalculate) {
            Button("Recalculate") {
                Task { await profileVm.recalculateTargets() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This replaces your numbers with fresh ones worked out from your latest weigh-in, and restarts your plan from today.")
        }
        .sheet(item: $planSheet, onDismiss: clearPendingPlanChange) { sheet in
            switch sheet {
            case .goalAndGoalWeight:
                // Two stages in one sheet: choosing Gain or Lose fat swaps this
                // content for the wheel rather than stacking a second sheet on a
                // sheet, which SwiftUI does not do reliably.
                if let pendingGoal {
                    goalWeightPicker(for: pendingGoal)
                } else {
                    goalPicker
                }
            case .activity:
                activityPicker
            }
        }
    }

    // MARK: - Parts

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Your targets")
                .font(.circaTitle)
                .foregroundStyle(Color.circaInk)
            Spacer(minLength: Circa.Space.rowGap)
            Button("Done") { dismiss() }
                .buttonStyle(.circa(.quiet))
        }
    }

    /// The saved numbers, with no certainty rule under them: a target is a value
    /// the app was given, not one it guessed. `design.md` rule 1 keeps the dotted
    /// mark for estimates, which is the next card.
    private func numbersCard(_ targets: Macros, profile: UserProfile) -> some View {
        CircaCard {
            VStack(alignment: .leading, spacing: Circa.Space.rowGap) {
                CircaSectionLabel("Daily targets")

                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text(whole(targets.calories))
                        .font(.circaMonoLarge)
                        .monospacedDigit()
                    Text("kcal")
                        .font(.circaRow)
                        .foregroundStyle(Color.circaInk2)
                }

                Text("\(whole(targets.protein)) g protein · \(whole(targets.carbs)) g carbs · \(whole(targets.fat)) g fat")
                    .font(.circaMono)
                    .monospacedDigit()
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)

                if let setAt = TargetsCopy.setAt(
                    weightKg: profile.targetsSetAtWeightKg,
                    on: profile.targetsSetOn,
                    unit: unit
                ) {
                    Text(setAt)
                        .font(.circaMono)
                        .foregroundStyle(Color.circaInk3)
                }
            }
        }
    }

    /// The formula's maintenance estimate, dotted because that is what it is.
    /// Nothing updates it from food logs or weigh-ins, and nothing calls it a burn.
    private func estimateCard(_ maintenance: Double) -> some View {
        CircaCard(.sunken) {
            VStack(alignment: .leading, spacing: 7) {
                CircaSectionLabel(TargetsCopy.maintenanceLabel)

                adaptive {
                    Text(TargetsCopy.maintenancePrefix)
                        .font(.circaBody)
                        .foregroundStyle(Color.circaInk2)
                    CircaEstimate(
                        TargetsCopy.maintenanceValue(maintenance),
                        certainty: .estimated,
                        font: .circaMonoLarge
                    )
                    Text(TargetsCopy.maintenanceSuffix)
                        .font(.circaBody)
                        .foregroundStyle(Color.circaInk2)
                }
            }
        }
    }

    private func planCard(_ profile: UserProfile) -> some View {
        CircaCard {
            VStack(alignment: .leading, spacing: Circa.Space.rowGap) {
                CircaSectionLabel("Your plan")

                row("Goal", profile.goalType?.displayName ?? "—") {
                    pendingGoal = nil
                    planSheet = .goalAndGoalWeight
                }

                // Maintain has no goal weight and gets a flat plan line, so the
                // row is absent rather than empty. Any other goal keeps the row
                // even with nothing saved yet, because a missing goal weight is
                // something to set, not something to hide.
                if profile.goalType != .maintain {
                    CircaHairline(weight: .inCard)
                    row(
                        "Goal weight",
                        profile.goalWeightKg.map { BodyWeight.displayString(kilograms: $0, unit: unit) } ?? "—"
                    ) {
                        // Straight to the wheel: the goal itself is not changing.
                        pendingGoal = profile.goalType
                        planSheet = .goalAndGoalWeight
                    }
                }

                CircaHairline(weight: .inCard)
                row("Daily activity", profile.activityLevel?.displayName ?? "—") {
                    planSheet = .activity
                }

                CircaHairline(weight: .inCard)
                // Shown, never edited. Weight comes from weigh-ins only —
                // `design.md` rule 4.
                row("Weight", profile.weightKg.map { BodyWeight.displayString(kilograms: $0, unit: unit) } ?? "—")
            }
        }
    }

    /// The only two ways a number changes on this screen, and there is no third.
    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                isEditingTargets = true
            } label: {
                Text("Edit").frame(maxWidth: .infinity)
            }
            .buttonStyle(.circa(.primary))

            Button {
                isConfirmingRecalculate = true
            } label: {
                Text("Recalculate").frame(maxWidth: .infinity)
            }
            .buttonStyle(.circa(.secondary))
        }
        .disabled(profileVm.isSaving)
        .opacity(profileVm.isSaving ? 0.6 : 1)
    }

    // MARK: - Pickers

    private var goalPicker: some View {
        pickerSheet(
            title: "Your goal",
            subtitle: "Changing this works out new targets and restarts your plan from today."
        ) {
            ForEach(GoalType.allCases, id: \.self) { goal in
                optionRow(
                    title: goal.displayName,
                    detail: goal.detail,
                    isSelected: profileVm.profile?.goalType == goal,
                    problem: SafetyLimits.goalProblem(
                        goal,
                        weightKg: profileVm.profile?.weightKg,
                        heightCm: profileVm.profile?.heightCm
                    )
                ) {
                    choose(goal)
                }
            }
        }
    }

    /// Stage two: the weight `goal` heads to. Only weights `SafetyLimits` allows are
    /// offered — the same rule the onboarding step uses — and nothing is saved until
    /// Save, so backing out leaves the old goal and old targets exactly as they were.
    @ViewBuilder
    private func goalWeightPicker(for goal: GoalType) -> some View {
        let options = goalWeightOptions(for: goal)

        pickerSheet(
            title: "Goal weight",
            subtitle: goal == profileVm.profile?.goalType
                ? "Changing this works out new targets and restarts your plan from today."
                : "\(goal.displayName) needs a weight to head to. Your plan restarts from today."
        ) {
            if options.isEmpty {
                Text("There's no goal weight available at your current weight and height.")
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                CircaCard(inset: EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)) {
                    Picker("Goal weight", selection: goalWeightSelection(options)) {
                        ForEach(options, id: \.self) { value in
                            Text("\(value) \(unit.shortLabel)").font(.circaMonoValue).tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }

                Button {
                    let picked = kilograms(nearestOption(in: options))
                    commit(.goal(goal, goalWeightKg: BodyWeight.roundedForStorage(picked)))
                } label: {
                    Text("Save").frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary, height: 52))
            }
        }
    }

    private var activityPicker: some View {
        pickerSheet(
            title: "Daily activity",
            subtitle: "Including exercise, what does a normal week look like? Changing this works out new targets."
        ) {
            ForEach(ActivityLevel.allCases, id: \.self) { level in
                optionRow(
                    title: level.displayName,
                    detail: level.detail,
                    isSelected: profileVm.profile?.activityLevel == level
                ) {
                    commit(.activity(level))
                }
            }
        }
    }

    /// Maintain is saved straight away. Gain and Lose fat move the sheet on to the
    /// wheel, because the goal weight sets the protein and fat basis and a goal
    /// without one would quietly use the current weight instead.
    private func choose(_ goal: GoalType) {
        guard goal != .maintain else {
            commit(.goal(.maintain, goalWeightKg: nil))
            return
        }

        selectedGoalWeight = nil
        pendingGoal = goal
    }

    private func commit(_ change: UserProfile.PlanChange) {
        planSheet = nil
        Task { await profileVm.updatePlan(change) }
    }

    private func clearPendingPlanChange() {
        pendingGoal = nil
        selectedGoalWeight = nil
    }

    // MARK: - Shapes

    @ViewBuilder
    private func row(_ title: String, _ value: String, action: (() -> Void)? = nil) -> some View {
        if let action {
            Button(action: action) {
                rowContent(title, value, isTappable: true)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
        } else {
            rowContent(title, value, isTappable: false)
                .accessibilityElement(children: .combine)
        }
    }

    private func rowContent(_ title: String, _ value: String, isTappable: Bool) -> some View {
        adaptive {
            Text(title)
                .font(.circaRow)
                .foregroundStyle(Color.circaInk2)
            if !isStacked {
                Spacer(minLength: Circa.Space.rowGap)
            }
            Text(value)
                .font(.circaMonoValue)
                .monospacedDigit()
                .foregroundStyle(Color.circaInk)
                .fixedSize(horizontal: false, vertical: true)
            // Dropped when the row goes vertical, where a chevron on its own line
            // reads as a stray mark. The row is still tappable.
            if isTappable, !isStacked {
                Image(systemName: "chevron.right")
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaInk3)
            }
        }
        .frame(minHeight: Circa.minHitTarget)
        .contentShape(Rectangle())
    }

    /// The shell every picker here shares: what is being changed, one line on what
    /// changing it does, and a way out that changes nothing.
    private func pickerSheet<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.circaTitle)
                            .foregroundStyle(Color.circaInk)
                        Text(subtitle)
                            .font(.circaBody)
                            .foregroundStyle(Color.circaInk2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: Circa.Space.rowGap)
                    Button("Cancel") { planSheet = nil }
                        .buttonStyle(.circa(.quiet))
                }

                content()
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.vertical, 18)
        }
        .circaPaper()
    }

    /// One choice in a picker. A `problem` replaces the description and disables the
    /// row — `SafetyLimits` decides, not this view.
    private func optionRow(
        title: String,
        detail: String,
        isSelected: Bool,
        problem: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            CircaCard(radius: Circa.Radius.cardSmall) {
                HStack(alignment: .top, spacing: Circa.Space.rowGap) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.circaEntryTitle)
                            .foregroundStyle(problem == nil ? Color.circaInk : Color.circaInk3)
                        Text(problem ?? detail)
                            .font(.circaCaption)
                            .foregroundStyle(Color.circaInk2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.circaRow.weight(.semibold))
                            .foregroundStyle(Color.circaInk)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(problem != nil)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// A row that is horizontal normally and vertical at accessibility sizes,
    /// without writing its contents twice.
    private func adaptive<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let layout = isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 6))
        return layout(content)
    }

    private func goalWeightOptions(for goal: GoalType) -> [Int] {
        guard let weightKg = profileVm.profile?.weightKg,
              let heightCm = profileVm.profile?.heightCm else { return [] }

        return SafetyLimits.goalWeightOptions(
            for: goal,
            currentWeightKg: weightKg,
            heightCm: heightCm,
            unit: unit
        )
    }

    private func goalWeightSelection(_ options: [Int]) -> Binding<Int> {
        Binding(
            get: { nearestOption(in: options) },
            set: { selectedGoalWeight = $0 }
        )
    }

    /// The allowed row nearest the value the wheel is on or, before it moves, the
    /// current goal weight — and failing that the current weight, so the wheel opens
    /// next to where the user is rather than suggesting anything.
    private func nearestOption(in options: [Int]) -> Int {
        let startKg = selectedGoalWeight.map { kilograms($0) }
            ?? profileVm.profile?.goalWeightKg
            ?? profileVm.profile?.weightKg
            ?? 0
        let target = inUnit(startKg)

        return options.min { abs(Double($0) - target) < abs(Double($1) - target) } ?? 0
    }

    private func inUnit(_ kg: Double) -> Double {
        unit == .kilograms ? kg : BodyWeight.pounds(fromKilograms: kg)
    }

    private func kilograms(_ value: Int) -> Double {
        unit == .kilograms ? Double(value) : BodyWeight.kilograms(fromPounds: Double(value))
    }

    /// Grams and calories as whole numbers, with the thousands grouped.
    private func whole(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }
}
