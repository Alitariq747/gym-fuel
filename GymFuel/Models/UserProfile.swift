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
    /// As stored. Read `resolvedPace` instead — see `GoalPace.resolved`.
    var goalPace: GoalPace? = nil
    /// Optional, set in Settings only. As stored — read `resolvedTargetWeightKg`.
    /// Never touches `weightKg`: only a weigh-in does.
    var targetWeightKg: Double? = nil

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
        case goalPace
        case targetWeightKg
    }

    /// The pace to use: `nil` for Maintain, `.steady` when missing or not
    /// offered for the goal.
    var resolvedPace: GoalPace? {
        GoalPace.resolved(goalPace, for: goalType)
    }

    /// The target weight to use: `nil` for Maintain, which has none.
    ///
    /// Resolved by goal only — never against today's weight. A target the trend
    /// has already reached must still read as set, or the check-in could never
    /// notice it was reached.
    var resolvedTargetWeightKg: Double? {
        (goalType ?? .defaultValue) == .maintain ? nil : targetWeightKg
    }

    /// Trims user-entered text. Call before persisting.
    mutating func normalize() {
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
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
    var goalPace: GoalPace? = nil

    /// Builds a completed profile, or `nil` if any required answer is missing.
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
            goalPace: GoalPace.resolved(goalPace, for: goalType)
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
