//
//  PaywallContextTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import Circa

@Suite("PaywallContext")
struct PaywallContextTests {
    /// A finished onboarding: targets saved and a plan started at `startKg`.
    private func profile(goal: GoalType, goalWeightKg: Double? = nil, startKg: Double = 85, targets: Bool = true) -> UserProfile {
        var profile = UserProfile(name: "", isOnboardingComplete: true, gender: .female)
        profile.goalType = goal
        profile.goalWeightKg = goalWeightKg
        profile.planStartedOn = "2026-10-08"
        profile.planStartWeightKg = startKg
        if targets {
            profile.targetCalories = 1950
            profile.targetProteinG = 120
            profile.targetCarbsG = 220
            profile.targetFatG = 65
        }
        return profile
    }

    private func answers(problem: LoggingProblem? = nil, meal: TriedMeal? = nil) -> OnboardingAnswers {
        var answers = OnboardingAnswers()
        answers.loggingProblem = problem
        answers.triedMeal = meal
        return answers
    }

    /// The fixture meal, with the mayonnaise changed from 2 tbsp when `mayonnaise` is set.
    private func meal(mayonnaise: Double? = nil, breakdown: Bool = true) -> TriedMeal {
        var sample = MealFixtures.sampleBreakdown
        sample.items[0].components[2].amount?.adjustedQuantity = mayonnaise
        return TriedMeal(
            words: "chicken sandwich and crisps",
            title: "Chicken sandwich and crisps",
            feedback: LogEntryFeedback(explanation: "A sandwich and crisps.", breakdown: breakdown ? sample : nil)
        )
    }

    private func context(_ profile: UserProfile, _ answers: OnboardingAnswers = OnboardingAnswers()) -> PaywallContext? {
        PaywallContext(profile: profile, answers: answers, unit: .kilograms)
    }

    @Test("No saved targets, no personal page")
    func needsSavedTargets() {
        #expect(context(profile(goal: .cut, goalWeightKg: 75, targets: false)) == nil)
    }

    @Test("The calories are the saved target")
    func calories() throws {
        #expect(try #require(context(profile(goal: .cut, goalWeightKg: 75))).calories == 1950)
    }

    @Test("Losing toward a goal reads the plan screen's own line")
    func planLineToGoal() throws {
        let losing = profile(goal: .cut, goalWeightKg: 75)
        let line = try #require(context(losing)?.planLine)
        #expect(line == PlanCopy.headline(for: try #require(WeightPlan(profile: losing)), unit: .kilograms))
        #expect(line.hasPrefix("From 85 kg today to 75 kg"))
    }

    @Test("Maintain stays around the starting weight")
    func planLineMaintain() {
        #expect(context(profile(goal: .maintain, startKg: 60))?.planLine == "Staying around 60 kg.")
    }

    @Test("Each answer brings its own subtitle, and no answer brings none")
    func subtitle() {
        for problem in LoggingProblem.allCases {
            #expect(context(profile(goal: .maintain), answers(problem: problem))?.subtitle == problem.paywallSubtitle)
        }
        #expect(context(profile(goal: .maintain))?.subtitle == nil)
    }

    @Test("An edited meal keeps its edited total and says it changed")
    func editedMeal() throws {
        let tried = meal(mayonnaise: 1)
        let shown = try #require(context(profile(goal: .maintain), answers(meal: tried))?.meal)
        let breakdown = try #require(tried.feedback.breakdown)
        #expect(shown.title == "Chicken sandwich and crisps")
        #expect(shown.kcal == MealBreakdownCalculator().total(of: breakdown).calories)
        #expect(shown.edited)
        #expect(shown.line.hasPrefix("You changed"))
    }

    @Test("A meal left as Circa guessed it is not called changed")
    func uneditedMeal() throws {
        let shown = try #require(context(profile(goal: .maintain), answers(meal: meal()))?.meal)
        #expect(!shown.edited)
        #expect(!shown.line.contains("changed"))
    }

    @Test("No meal, or one with no breakdown, shows no meal")
    func noMeal() {
        #expect(context(profile(goal: .maintain))?.meal == nil)
        #expect(context(profile(goal: .maintain), answers(meal: meal(breakdown: false)))?.meal == nil)
    }

    @Test("No meal line calls the meal saved")
    func neverSaved() {
        for edited in [true, false] {
            let line = PaywallContext.Meal(title: "", kcal: 0, edited: edited).line
            #expect(!line.lowercased().contains("save"))
        }
    }
}
