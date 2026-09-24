//
//  TargetReconciler.swift
//  GymFuel
//

import Foundation

/// One of the four numbers the targets editor types. Declaration order is the
/// order they are shown in and the order changes are listed in.
enum TargetField: CaseIterable {
    case calories, protein, carbs, fat

    /// Calories are already kcal, so `macros[field] * field.kcalPerGram` is
    /// uniform across all four.
    var kcalPerGram: Double {
        switch self {
        case .calories: return 1
        case .protein, .carbs: return 4
        case .fat: return 9
        }
    }
}

/// One line of "before → after" for the editor's change summary.
struct TargetChange: Equatable, Identifiable {
    let field: TargetField
    let before: Double
    let after: Double

    var id: TargetField { field }
}

/// Reconciles a number the user typed with the three they did not.
///
/// The editor asks before it moves anything, so each of these is one answer the
/// user can pick — none of them is applied on its own. Pure: no Firebase, no UI.
enum TargetReconciler {

    /// Which of the four the user moved away from `start`.
    ///
    /// Compared field by field, **never** by checking whether the numbers add up:
    /// a saved target's own grams already miss its calories by a kcal or two —
    /// 2,000 kcal against 162 g protein, 192 g carbs and 65 g fat is 2,001 — so
    /// an arithmetic test would report an edit the moment the sheet opened.
    static func changedFields(in typed: Macros, from start: Macros) -> Set<TargetField> {
        Set(TargetField.allCases.filter { typed[$0].rounded() != start[$0].rounded() })
    }

    /// After a calorie edit: protein and fat come back from the goal's grams per
    /// kg of the basis weight, carbs fill what is left, and the floors hold.
    ///
    /// The same rule `MacroTargetCalculator.targets(for:)` applies, reached the
    /// same way, so typing the app's own calorie number returns the app's own
    /// targets.
    static func recalculatingMacros(
        calories: Double,
        basisKg: Double,
        goal: GoalType,
        gender: Gender
    ) -> Macros {
        MacroTargetCalculator.edited(
            calories: calories,
            proteinG: basisKg * goal.proteinPerKg,
            fatG: basisKg * goal.fatPerKg,
            gender: gender
        )
    }

    /// After a macro edit: the three macros stand exactly as typed, and the
    /// calories become what they cost. The floor still wins, and its surplus goes
    /// to carbs — where `MacroTargetCalculator.edited` always puts surplus.
    static func recalculatingCalories(_ typed: Macros, gender: Gender) -> Macros {
        let protein = max(typed.protein.rounded(), 0)
        let carbs = max(typed.carbs.rounded(), 0)
        let fat = max(typed.fat.rounded(), 0)
        let cost = calorieCost(of: Macros(calories: 0, protein: protein, carbs: carbs, fat: fat))
        let floor = MacroTargetCalculator.minimumCalories(gender: gender, proteinG: protein, fatG: fat)

        guard cost < floor else {
            return Macros(calories: cost, protein: protein, carbs: carbs, fat: fat)
        }
        return MacroTargetCalculator.edited(calories: floor, proteinG: protein, fatG: fat, gender: gender)
    }

    /// Carbs first: it is the macro this app fills everywhere else. Then protein,
    /// which shares carbs' 4 kcal a gram, so a rounding remainder landing there
    /// costs less than one landing on fat.
    private static let fillOrder: [TargetField] = [.carbs, .protein, .fat]

    /// After a macro edit: the calories and every macro in `touched` stand, and
    /// the untouched macros take up the difference in proportion to what they
    /// already hold.
    ///
    /// Nil when no macro is free to absorb, or when the held macros alone already
    /// cost more than the calories — there is no answer that keeps both. The
    /// editor offers this choice only when it is non-nil.
    static func adjustingMacros(
        _ typed: Macros,
        touched: Set<TargetField>,
        gender: Gender
    ) -> Macros? {
        let free = fillOrder.filter { !touched.contains($0) }
        guard let absorber = free.first else { return nil }

        var result = typed
        result.calories = typed.calories.rounded()
        for field in fillOrder { result[field] = max(typed[field].rounded(), 0) }

        let remainder = result.calories - kcal(of: result, in: fillOrder.filter(touched.contains))
        guard remainder >= 0 else { return nil }

        let haveKcal = kcal(of: result, in: free)
        for field in free.dropFirst() {
            // Free macros holding nothing have no proportions to preserve, so the
            // remainder splits evenly instead.
            let share = haveKcal > 0
                ? remainder * (result[field] * field.kcalPerGram) / haveKcal
                : remainder / Double(free.count)
            result[field] = max((share / field.kcalPerGram).rounded(), 0)
        }

        // The absorber fills what is left, so whole-gram rounding lands on one
        // named field rather than scattering across three.
        let spent = kcal(of: result, in: fillOrder.filter { $0 != absorber })
        result[absorber] = max(((result.calories - spent) / absorber.kcalPerGram).rounded(), 0)

        let minimum = MacroTargetCalculator.minimumCalories(
            gender: gender,
            proteinG: result.protein,
            fatG: result.fat
        )
        guard result.calories >= minimum else { return nil }
        return result
    }

    /// Every line that moved, in field order.
    static func changes(from before: Macros, to after: Macros) -> [TargetChange] {
        TargetField.allCases.compactMap { field in
            let was = before[field].rounded()
            let now = after[field].rounded()
            guard was != now else { return nil }
            return TargetChange(field: field, before: was, after: now)
        }
    }

    /// What these macros cost, by the Atwater factors. Ignores `calories`.
    static func calorieCost(of macros: Macros) -> Double {
        kcal(of: macros, in: fillOrder)
    }

    private static func kcal(of macros: Macros, in fields: [TargetField]) -> Double {
        fields.reduce(0) { $0 + macros[$1] * $1.kcalPerGram }
    }
}

/// Field access, so the reconciler's arithmetic reads the same for all four.
/// Kept here rather than on `Macros`: `TargetField` is an editing concept, and a
/// meal's macros have no use for it.
extension Macros {
    subscript(field: TargetField) -> Double {
        get {
            switch field {
            case .calories: return calories
            case .protein: return protein
            case .carbs: return carbs
            case .fat: return fat
            }
        }
        set {
            switch field {
            case .calories: calories = newValue
            case .protein: protein = newValue
            case .carbs: carbs = newValue
            case .fat: fat = newValue
            }
        }
    }
}
