//
//  UserProfileTargetsTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("Saved targets")
struct UserProfileTargetsTests {
    private let calculator = MacroTargetCalculator()
    private let targets = MacroTargets(
        macros: Macros(calories: 2_000, protein: 130, carbs: 224, fat: 65),
        maintenanceCalories: 2_470
    )

    /// 85 kg, 180 cm, 30, losing fat, with nothing saved yet.
    private let sample = UserProfile(
        name: "",
        heightCm: 180,
        age: 30,
        weightKg: 85,
        goalType: .cut,
        activityLevel: .mostlySitting,
        isOnboardingComplete: true,
        gender: .male
    )

    /// Midday on the local day `key` names.
    private func day(_ key: String) throws -> Date {
        try #require(DateKey.date(from: key))
    }

    @Test("Setting targets saves the numbers, the day and the weight")
    func setTargetsStamps() throws {
        var profile = sample
        profile.setTargets(targets, on: try day("2026-09-03"))

        #expect(profile.savedTargets == targets.macros)
        #expect(profile.maintenanceCalories == 2_470)
        #expect(profile.targetsSetOn == "2026-09-03")
        #expect(profile.targetsSetAtWeightKg == 85)
    }

    @Test("Setting targets again replaces the old ones")
    func setTargetsOverwrites() throws {
        var profile = sample
        profile.setTargets(targets, on: try day("2026-09-03"))

        profile.weightKg = 80
        let newer = MacroTargets(
            macros: Macros(calories: 1_900, protein: 128, carbs: 205, fat: 64),
            maintenanceCalories: 2_380
        )
        profile.setTargets(newer, on: try day("2026-10-01"))

        #expect(profile.savedTargets == newer.macros)
        #expect(profile.maintenanceCalories == 2_380)
        #expect(profile.targetsSetOn == "2026-10-01")
        #expect(profile.targetsSetAtWeightKg == 80)
    }

    @Test("Starting the plan saves the day and the weight")
    func startPlanStamps() throws {
        var profile = sample
        profile.startPlan(on: try day("2026-09-03"))

        #expect(profile.planStartedOn == "2026-09-03")
        #expect(profile.planStartWeightKg == 85)
    }

    /// The rule Step 4c exists for: weigh-ins update `weightKg` and nothing else.
    @Test("A weigh-in changes the weight and leaves the saved targets alone")
    func weighInLeavesTargets() throws {
        var profile = sample
        profile.setTargets(targets, on: try day("2026-09-03"))

        profile.weightKg = 80

        #expect(profile.savedTargets == targets.macros)
        #expect(profile.targetsSetAtWeightKg == 85)
    }

    @Test("There are no saved targets until all four numbers exist")
    func savedTargetsNeedAllFour() throws {
        var profile = sample
        #expect(profile.savedTargets == nil)

        profile.setTargets(targets, on: try day("2026-09-03"))
        profile.targetFatG = nil
        #expect(profile.savedTargets == nil)
    }

    /// A field left out of `CodingKeys` is dropped silently rather than failing
    /// to compile, so this is the only thing that catches it.
    @Test("Every saved field survives encoding and decoding")
    func roundTrip() throws {
        var profile = sample
        profile.setTargets(targets, on: try day("2026-09-03"))
        profile.startPlan(on: try day("2026-09-03"))

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)

        #expect(decoded == profile)
    }

    @Test("A profile saved before targets were stored decodes with none")
    func olderProfileDecodes() throws {
        // Nil fields are left out when encoding, so this is the shape of a
        // document written before Step 4c.
        let data = try JSONEncoder().encode(sample)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)

        #expect(decoded.savedTargets == nil)
        #expect(decoded.maintenanceCalories == nil)
        #expect(decoded.targetsSetOn == nil)
        #expect(decoded.planStartedOn == nil)
    }

    // MARK: - Keeping Settings and the targets screen in step (Step 4d)

    /// `ProfileView`'s Save writes its whole draft, so numbers changed on the
    /// targets screen have to survive being merged back into it.
    @Test("Adopting Settings edits keeps the saved targets, the plan and the weight")
    func adoptSettingsEditsKeepsTargets() throws {
        var saved = sample
        saved.setTargets(targets, on: try day("2026-09-03"))
        saved.startPlan(on: try day("2026-09-03"))
        saved.goalWeightKg = 78

        // A draft opened before the targets screen changed anything.
        var draft = sample
        draft.name = "Ahmad"
        draft.age = 31
        draft.heightCm = 182
        draft.gender = .female
        draft.goalType = .maintain
        draft.activityLevel = .active
        draft.targetCalories = 9_999
        draft.planStartedOn = "2026-01-01"
        draft.goalWeightKg = nil
        draft.weightKg = 70

        var merged = saved
        merged.adoptSettingsEdits(from: draft)

        // What Settings owns comes from the draft.
        #expect(merged.name == "Ahmad")
        #expect(merged.age == 31)
        #expect(merged.heightCm == 182)
        #expect(merged.gender == .female)

        // Goal and activity are the targets screen's, so a draft cannot move them
        // even while it still carries them.
        #expect(merged.goalType == .cut)
        #expect(merged.activityLevel == .mostlySitting)

        // Everything else stays as saved — including the weight, which no draft
        // may write.
        #expect(merged.savedTargets == targets.macros)
        #expect(merged.targetsSetOn == "2026-09-03")
        #expect(merged.planStartedOn == "2026-09-03")
        #expect(merged.goalWeightKg == 78)
        #expect(merged.weightKg == 85)
    }

    // MARK: - Changing the plan (Step 4d Part C)

    @Test("A new goal weight restarts the plan from today and the current weight")
    func planChangeRestartsThePlan() throws {
        var profile = sample
        profile.weightKg = 83
        profile.goalWeightKg = 80
        profile.setTargets(targets, on: try day("2026-09-03"))
        profile.startPlan(on: try day("2026-09-03"))

        let changed = profile.applyPlanChange(
            .goal(.cut, goalWeightKg: 78),
            on: try day("2026-09-19"),
            using: calculator
        )

        #expect(changed)
        #expect(profile.goalWeightKg == 78)
        #expect(profile.planStartedOn == "2026-09-19")
        #expect(profile.planStartWeightKg == 83)
        #expect(profile.targetsSetOn == "2026-09-19")
        #expect(profile.targetsSetAtWeightKg == 83)
        // Protein and fat follow the new goal weight: 78 kg is under the BMI 25 cap
        // of 81 kg for 180 cm, so 78 × 1.6 and 78 × 0.8.
        #expect(profile.targetProteinG == 125)
        #expect(profile.targetFatG == 62)
    }

    @Test("Switching to Maintain drops the goal weight, even one passed in")
    func planChangeToMaintainClearsGoalWeight() throws {
        var profile = sample
        profile.goalWeightKg = 78
        profile.setTargets(targets, on: try day("2026-09-03"))

        let changed = profile.applyPlanChange(
            .goal(.maintain, goalWeightKg: 78),
            on: try day("2026-09-19"),
            using: calculator
        )

        #expect(changed)
        #expect(profile.goalType == .maintain)
        #expect(profile.goalWeightKg == nil)
        // Maintain works protein and fat from the current weight, capped at BMI 25:
        // 85 kg at 180 cm caps at 81 kg, so 81 × 1.6 and 81 × 0.8.
        #expect(profile.targetProteinG == 130)
        #expect(profile.targetFatG == 65)
    }

    @Test("A new activity level works out new targets and restarts the plan")
    func planChangeActivity() throws {
        let today = try day("2026-09-19")

        var sitting = sample
        let sittingChanged = sitting.applyPlanChange(.activity(.mostlySitting), on: today, using: calculator)

        var veryActive = sample
        let veryActiveChanged = veryActive.applyPlanChange(.activity(.veryActive), on: today, using: calculator)

        #expect(sittingChanged)
        #expect(veryActiveChanged)

        let sittingCalories = try #require(sitting.targetCalories)
        let veryActiveCalories = try #require(veryActive.targetCalories)

        #expect(veryActive.activityLevel == .veryActive)
        #expect(veryActiveCalories > sittingCalories)
        #expect(veryActive.planStartedOn == "2026-09-19")
        #expect(veryActive.planStartWeightKg == 85)
    }

    /// A goal saved with numbers that do not match it would be worse than no change
    /// at all, so nothing moves.
    @Test("A plan change is refused when targets cannot be worked out")
    func planChangeNeedsAFullProfile() throws {
        var profile = sample
        profile.age = nil

        let changed = profile.applyPlanChange(
            .activity(.active),
            on: try day("2026-09-19"),
            using: calculator
        )

        #expect(changed == false)
        #expect(profile.activityLevel == .mostlySitting)
        #expect(profile.planStartedOn == nil)
        #expect(profile.savedTargets == nil)
    }

    // MARK: - What onboarding saves (Step 4f)

    /// The sample as onboarding answers, losing toward 78 kg.
    private let answers = OnboardingAnswers(
        gender: .male,
        age: 30,
        heightCm: 180,
        weightKg: 85,
        goalType: .cut,
        activityLevel: .mostlySitting,
        goalWeightKg: 78
    )

    @Test("Onboarding saves the worked-out targets and starts the plan that day")
    func plannedProfileWorksOutTargets() throws {
        let today = try day("2026-09-19")
        let profile = try #require(answers.plannedProfile(id: "uid", on: today, using: calculator))
        let workedOut = try #require(calculator.targets(for: profile))

        #expect(profile.id == "uid")
        #expect(profile.isOnboardingComplete)
        #expect(profile.savedTargets == workedOut.macros)
        #expect(profile.maintenanceCalories == workedOut.maintenanceCalories)
        #expect(profile.targetsSetOn == "2026-09-19")
        #expect(profile.targetsSetAtWeightKg == 85)
        #expect(profile.planStartedOn == "2026-09-19")
        #expect(profile.planStartWeightKg == 85)
    }

    /// The plan screen's Edit: what the user typed is what gets saved.
    @Test("Numbers edited on the plan screen are saved against the same estimate")
    func plannedProfileKeepsEdits() throws {
        let today = try day("2026-09-19")
        let unedited = try #require(answers.plannedProfile(id: "uid", on: today, using: calculator))

        var edited = answers
        edited.editedTargets = MacroTargetCalculator.edited(calories: 2_100, proteinG: 140, fatG: 60, gender: .male)
        let profile = try #require(edited.plannedProfile(id: "uid", on: today, using: calculator))

        #expect(profile.savedTargets == edited.editedTargets)
        #expect(profile.savedTargets != unedited.savedTargets)
        #expect(profile.maintenanceCalories == unedited.maintenanceCalories)
        #expect(profile.planStartedOn == "2026-09-19")
    }

    @Test("Nothing is planned while an answer is missing")
    func plannedProfileNeedsEveryAnswer() throws {
        let today = try day("2026-09-19")
        var missing = answers
        missing.activityLevel = nil

        #expect(missing.plannedProfile(id: "uid", on: today, using: calculator) == nil)
    }

    @Test("Maintain saves no goal weight, even one left from an earlier answer")
    func plannedProfileDropsGoalWeightOnMaintain() throws {
        let today = try day("2026-09-19")
        var maintaining = answers
        maintaining.goalType = .maintain

        let profile = try #require(maintaining.plannedProfile(id: "uid", on: today, using: calculator))
        #expect(profile.goalWeightKg == nil)
    }
}
