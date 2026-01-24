//
//  FuelTimelineSection.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/01/2026.
//

import SwiftUI

struct FuelTimelineSection: View {
    
    let dayLog: DayLog
    let preMeals: [Meal]
    let postMeals: [Meal]
    let supportMeals: [Meal]
    let restMeals: [Meal]
    
    let fuelImpactByMealId: [String: DayLogViewModel.MealFuelImpact]
    
    let onSelectMeal: (Meal) -> Void
    
    private var isTrainingDay: Bool {
        dayLog.isTrainingDay
    }
    
    private var sortedPreMeals: [Meal] {
        preMeals.sorted { $0.loggedAt < $1.loggedAt }
    }
    private var sortedPostMeals: [Meal] {
        postMeals.sorted { $0.loggedAt < $1.loggedAt }
    }

    private var sortedSupportMeals: [Meal] {
        supportMeals.sorted { $0.loggedAt < $1.loggedAt }
    }

    private var sortedRestMeals: [Meal] {
        restMeals.sorted { $0.loggedAt < $1.loggedAt }
    }
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 12) {
                // High-level title for the whole block
                Text("Fuel Timeline")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 4)

            
                if isTrainingDay {
                    trainingTimeline
                } else {
                    restTimeline
                }
            }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    


    var trainingTimeline: some View {
        VStack(alignment: .leading, spacing: 16) {

            // PRE-WORKOUT
            if !sortedPreMeals.isEmpty {
                SectionHeader(tag: .preWorkout)

                VStack(spacing: 12) {
                    ForEach(sortedPreMeals) { meal in
                        let impact = fuelImpactByMealId[meal.id]
                        Button {
                            onSelectMeal(meal)
                        } label: {
                            TimelineMealRow(
                                meal: meal,
                                tag: .preWorkout, impact: impact
                            )
                        }
                        .buttonStyle(.plain)
                    
                    }
                }
            }

            // POST-WORKOUT
            if !sortedPostMeals.isEmpty {
                SectionHeader(tag: .postWorkout)

                VStack(spacing: 12) {
                    ForEach(sortedPostMeals) { meal in
                        let impact = fuelImpactByMealId[meal.id]
                        Button {
                            onSelectMeal(meal)
                        } label: {
                            TimelineMealRow(
                                meal: meal,
                                tag: .postWorkout, impact: impact
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // SUPPORT MEALS
            if !sortedSupportMeals.isEmpty {
                SectionHeader(tag: .otherOnTrainingDay)

                VStack(spacing: 12) {
                    ForEach(sortedSupportMeals) { meal in
                        let impact = fuelImpactByMealId[meal.id]
                        Button {
                            onSelectMeal(meal)
                        } label: {
                            TimelineMealRow(
                                meal: meal,
                                tag: .otherOnTrainingDay, impact: impact
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var restTimeline: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !sortedRestMeals.isEmpty {
                SectionHeader(tag: .restDay)

                VStack(spacing: 12) {
                    ForEach(sortedRestMeals) { meal in
                        let impact = fuelImpactByMealId[meal.id]
                        Button {
                            onSelectMeal(meal)
                        } label: {
                            TimelineMealRow(
                                meal: meal,
                                tag: .restDay, impact: impact
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                // No meals on a rest day yet – simple empty state
                Text("No meals logged yet for this rest day.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
        }
    }


    private struct SectionHeader: View {
        let tag: MealTimingTag

        var body: some View {
            HStack(spacing: 8) {
               

                VStack(alignment: .leading, spacing: 2) {
                    Text(tag.title)
                        .font(.subheadline.weight(.semibold))

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 4)
        }

        private var subtitle: String {
            switch tag {
            case .preWorkout:
                return "Meals that fuel you before training."
            case .postWorkout:
                return "Meals that help you recover and grow."
            case .otherOnTrainingDay:
                return "Support meals for the rest of your training day."
            case .restDay:
                return "Meals to support recovery on a non-training day."
            }
        }
    }

}

#Preview {
    ZStack {
        AppBackground()
        
        ScrollView {
            
            FuelTimelineSection(dayLog: DayLog.demoTrainingDay, preMeals: Meal.demoMeals(forTrainingDay: DayLog.demoTrainingDay), postMeals: Meal.demoMeals(forTrainingDay: DayLog.demoTrainingDay), supportMeals: Meal.demoMeals(forTrainingDay: DayLog.demoTrainingDay), restMeals: Meal.demoMeals(forRestDay: DayLog.demoRestDay), fuelImpactByMealId: [:], onSelectMeal: { _ in print("Hello")})
        }
    }
}
