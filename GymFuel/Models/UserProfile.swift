//
//  UserProfile.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/12/2025.
//

import Foundation

enum Gender: String, CaseIterable, Codable, Equatable {
    case male = "male"
    case female = "female"
    case preferNotToSay = "prefer_not_to_say"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Gender(rawValue: rawValue) ?? .preferNotToSay
    }

    var displayName: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        case .preferNotToSay:
            return "Prefer not to say"
        }
    }

    var symbol: String {
        switch self {
        case .male:
            return "♂"
        case .female:
            return "♀"
        case .preferNotToSay:
            return "–"
        }
    }
}

/// The single source of truth for a user's profile — used both in-app and as the
/// Firestore document body. `id` is the Firestore document ID and is never written
/// as a field (it is excluded from `CodingKeys`); callers set it from the snapshot's
/// `documentID` after decoding.
struct UserProfile: Codable, Identifiable, Equatable {
    var id: String = ""
    var name: String
    var heightCm: Double?
    var age: Int?
    var weightKg: Double?
    var goalType: GoalType?
    var activityLevel: ActivityLevel?
    var isOnboardingComplete: Bool
    var gender: Gender

   
    /// Where the plan is headed. Nil on Maintain, which has no goal weight.
    var goalWeightKg: Double?
    // The `…On` fields are `"yyyy-MM-dd"` day keys from `DateKey`, like weigh-ins.
    var planStartedOn: String?
    var planStartWeightKg: Double?
    var targetCalories: Double?
    var targetProteinG: Double?
    var targetCarbsG: Double?
    var targetFatG: Double?
    var maintenanceCalories: Double?
    var targetsSetOn: String?
    var targetsSetAtWeightKg: Double?

    /// Firestore field names. `id` is intentionally omitted so the document
    /// identifier is never persisted as a field.
    private enum CodingKeys: String, CodingKey {
        case name
        case heightCm
        case age
        case weightKg
        case goalType
        case activityLevel
        case isOnboardingComplete
        case gender
        case goalWeightKg
        case planStartedOn
        case planStartWeightKg
        case targetCalories
        case targetProteinG
        case targetCarbsG
        case targetFatG
        case maintenanceCalories
        case targetsSetOn
        case targetsSetAtWeightKg
    }

    /// Trims user-entered text. Call before persisting.
    mutating func normalize() {
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Saved targets and plan

extension UserProfile {
    /// The daily targets as saved, or nil until they have been worked out once.
    /// Screens read these; nothing recalculates them on read.
    var savedTargets: Macros? {
        guard let targetCalories, let targetProteinG, let targetCarbsG, let targetFatG else {
            return nil
        }
        return Macros(calories: targetCalories, protein: targetProteinG, carbs: targetCarbsG, fat: targetFatG)
    }

    /// Saves `targets` as the current ones, stamped with the day and the weight
    /// they were set at — "Set at 85 kg on 3 Sep". Replaces whatever was saved.
    mutating func setTargets(_ targets: MacroTargets, on date: Date) {
        targetCalories = targets.macros.calories
        targetProteinG = targets.macros.protein
        targetCarbsG = targets.macros.carbs
        targetFatG = targets.macros.fat
        maintenanceCalories = targets.maintenanceCalories
        targetsSetOn = DateKey.key(for: date)
        targetsSetAtWeightKg = weightKg
    }

    /// Starts the plan line from `date` and the current weight.
    mutating func startPlan(on date: Date) {
        planStartedOn = DateKey.key(for: date)
        planStartWeightKg = weightKg
    }

    /// A change to the plan itself, rather than to the numbers.
    ///
    /// Both cases go through `applyPlanChange`, because both change the targets
    /// *and* where the plan line starts — `build-order.md` Step 4, *The rules*.
    /// A goal weight is part of the goal case rather than a case of its own: the
    /// two are one decision, and the goal weight sets the protein and fat basis.
    enum PlanChange {
        case goal(GoalType, goalWeightKg: Double?)
        case activity(ActivityLevel)
    }

    /// Applies `change`, works out fresh targets, and restarts the plan line from
    /// `date` and the current weight.
    ///
    /// Returns false when targets cannot be worked out — an account missing an age,
    /// height or weight — in which case nothing is changed at all, rather than a
    /// goal being saved that the numbers do not match.
    mutating func applyPlanChange(
        _ change: PlanChange,
        on date: Date,
        using calculator: MacroTargetCalculator
    ) -> Bool {
        var updated = self

        switch change {
        case .goal(let goal, let goalWeightKg):
            updated.goalType = goal
            // Maintain has no goal weight, and one left behind would still reach
            // the protein and fat basis.
            updated.goalWeightKg = goal == .maintain ? nil : goalWeightKg
        case .activity(let level):
            updated.activityLevel = level
        }

        guard let targets = calculator.targets(for: updated) else { return false }

        updated.setTargets(targets, on: date)
        updated.startPlan(on: date)
        self = updated
        return true
    }

    /// Overlays the fields the Settings screen edits onto this profile.
    ///
    /// `ProfileView` holds a draft copy and its Save writes **all** of it, so a
    /// target changed on the targets screen would be written back stale the next
    /// time Settings saves. Re-seeding the draft from the saved profile through
    /// this keeps both halves current.
    ///
    /// The field list is exactly what `ProfileView.isDirty` compares, and the two
    /// change together. Goal and activity are absent because the targets screen
    /// owns them, not Settings.
    mutating func adoptSettingsEdits(from draft: UserProfile) {
        name = draft.name
        gender = draft.gender
        age = draft.age
        heightCm = draft.heightCm
    }
}

/// In-memory onboarding answers. Never persisted. Every answer the user actively
/// provides during onboarding is optional because it may not have been given yet.
/// (`name` and `gender` keep non-optional defaults so the step views can bind to
/// them directly, matching the previous onboarding data flow.)
struct OnboardingAnswers {
    var name: String = ""
    var gender: Gender = .preferNotToSay
    var age: Int? = nil
    var heightCm: Double? = nil
    var weightKg: Double? = nil
    var goalType: GoalType? = nil
    var activityLevel: ActivityLevel? = nil
    var goalWeightKg: Double? = nil

    /// Builds a completed profile, or `nil` if any required answer is missing.
    /// A goal weight left over from an earlier answer is dropped on Maintain.
    func toProfile(id: String) -> UserProfile? {
        guard
            let age,
            let heightCm,
            let weightKg,
            let goalType,
            let activityLevel
        else { return nil }

        return UserProfile(
            id: id,
            name: name,
            heightCm: heightCm,
            age: age,
            weightKg: weightKg,
            goalType: goalType,
            activityLevel: activityLevel,
            isOnboardingComplete: true,
            gender: gender,
            goalWeightKg: goalType == .maintain ? nil : goalWeightKg
        )
    }
}

#if DEBUG
extension UserProfile {
    static let preview = UserProfile(
        id: "preview",
        name: "Ahmad (Preview)",
        heightCm: 175,
        age: 38,
        weightKg: 83,
        goalType: .leanBulk,
        activityLevel: .mostlySitting,
        isOnboardingComplete: true,
        gender: .male
    )
}
#endif
