//
//  PlanCopy.swift
//  GymFuel
//

import Foundation

/// What the onboarding plan screen says: where the plan heads, and one reason for
/// each target. Pure: no UI, no Firebase.
///
/// Every number in a sentence comes from the rule that made it — the plan's pace,
/// the calculator's grams per kilogram — so changing a rule changes the words with
/// it. Nothing here calls the maintenance estimate a burn: `build-order.md`
/// Step 4, *The rules*.
enum PlanCopy {

    /// One reason for each target. Calories have none when the target is the estimate.
    struct Reasons: Equatable {
        let calories: CalorieStep?
        let protein: String
        let carbs: String
        let fat: String
    }

    /// The middle line of the sum the plan screen shows: the maintenance estimate,
    /// this step, then the target.
    struct CalorieStep: Equatable {
        /// "To lose about 0.4 kg a week"
        let reason: String
        /// "− 470"
        let amount: String
    }

    /// What a number the user typed says in place of its working, which no longer
    /// describes it.
    static let setByYou = "You set this target yourself."
    /// The same, as the step in the calorie sum.
    static let yourChange = "Your change"

    /// True whatever was typed: carbs are always what the other three leave.
    static let carbs = "What the calories leave after protein and fat."

    /// "From 85 kg today to 75 kg, around March 2027."
    ///
    /// Month and year only: the pace is an estimate, and a day would claim more
    /// than it knows. A line that never reaches the goal gets no date at all,
    /// because `WeightPlan.goalDate` promises none.
    static func headline(for line: WeightPlan, unit: BodyWeightUnit) -> String {
        let start = weight(line.startWeightKg, unit)
        guard let goalWeightKg = line.goalWeightKg else { return "Staying around \(start)." }

        let goal = weight(goalWeightKg, unit)
        guard let goalDate = line.goalDate else { return "From \(start) today toward \(goal)." }

        return "From \(start) today to \(goal), around \(goalDate.formatted(.dateTime.month(.wide).year()))."
    }

    /// One reason for each target saved on `profile`. A target that differs from
    /// `workedOut` was typed, so its reason says that instead.
    ///
    /// `workedOut` is passed in rather than worked out here: only the caller knows
    /// which numbers the saved ones should be compared against. Nil when the
    /// profile has no saved targets, estimate or weight.
    static func reasons(
        for profile: UserProfile,
        workedOut: Macros,
        unit: BodyWeightUnit,
        calculator: MacroTargetCalculator
    ) -> Reasons? {
        guard let targets = profile.savedTargets,
              let maintenanceCalories = profile.maintenanceCalories,
              let startWeightKg = profile.planStartWeightKg ?? profile.weightKg,
              let basis = calculator.basis(for: profile)?.source else { return nil }

        let goal = profile.goalType ?? .defaultValue
        // The pace the plan line is drawn at, so the words and the line agree.
        let weeklyChangeKg = WeightPlan.weeklyChangeKg(
            goal: goal,
            startWeightKg: startWeightKg,
            maintenanceCalories: maintenanceCalories,
            gender: profile.gender
        )
        let step = calorieStep(
            targetKcal: targets.calories,
            maintenanceKcal: maintenanceCalories,
            weeklyChangeKg: weeklyChangeKg,
            unit: unit
        )

        return Reasons(
            calories: targets.calories == workedOut.calories
                ? step
                : step.map { CalorieStep(reason: yourChange, amount: $0.amount) },
            protein: targets.protein == workedOut.protein ? perKg(goal.proteinPerKg, of: basis) : setByYou,
            carbs: targets.carbs == workedOut.carbs ? carbs : setByYou,
            fat: targets.fat == workedOut.fat ? perKg(goal.fatPerKg, of: basis) : setByYou
        )
    }

    /// The step from the maintenance estimate to the calorie target. Nil when the
    /// target is the estimate.
    static func calorieStep(
        targetKcal: Double,
        maintenanceKcal: Double,
        weeklyChangeKg: Double,
        unit: BodyWeightUnit
    ) -> CalorieStep? {
        let difference = (targetKcal - maintenanceKcal).rounded()
        guard difference != 0 else { return nil }

        let reason: String
        if difference < 0, weeklyChangeKg < 0 {
            reason = "To lose \(pace(weeklyChangeKg, unit)) a week"
        } else if difference > 0, weeklyChangeKg > 0 {
            reason = "To gain \(pace(weeklyChangeKg, unit)) a week"
        } else {
            // Only the calorie floor lands here: it held the target at or above the
            // estimate, so the plan line has no room to slope.
            reason = "Raised to the lowest this app sets"
        }
        let amount = abs(difference).formatted(.number.precision(.fractionLength(0)))
        return CalorieStep(reason: reason, amount: "\(difference < 0 ? "−" : "+") \(amount)")
    }

    /// "1.6 g for each kg of your goal weight." Names the weight the calculator
    /// used, which is not always the one the user picked.
    static func perKg(_ grams: Double, of basis: ProteinFatBasis.Source) -> String {
        let whichWeight: String
        switch basis {
        case .goalWeight: whichWeight = "your goal weight"
        case .currentWeight: whichWeight = "your weight"
        case .topHealthyWeight: whichWeight = "the top healthy weight for your height"
        }
        return "\(grams.formatted(.number.precision(.fractionLength(1)))) g for each kg of \(whichWeight)."
    }

    // MARK: - Numbers in words

    /// "about 0.4 kg", or "less than 0.1 kg" when one decimal place would show 0.0.
    private static func pace(_ weeklyChangeKg: Double, _ unit: BodyWeightUnit) -> String {
        let perWeek = abs(unit == .kilograms ? weeklyChangeKg : BodyWeight.pounds(fromKilograms: weeklyChangeKg))
        let oneDecimal: FloatingPointFormatStyle<Double> = .number.precision(.fractionLength(1))

        guard perWeek >= 0.05 else { return "less than \((0.1).formatted(oneDecimal)) \(unit.shortLabel)" }
        return "about \(perWeek.formatted(oneDecimal)) \(unit.shortLabel)"
    }

    /// Whole units, as the goal weight wheel offers them.
    private static func weight(_ kg: Double, _ unit: BodyWeightUnit) -> String {
        let value = unit == .kilograms ? kg : BodyWeight.pounds(fromKilograms: kg)
        return "\(value.formatted(.number.precision(.fractionLength(0)))) \(unit.shortLabel)"
    }
}
