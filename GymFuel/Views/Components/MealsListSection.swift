//
//  MealsListSection.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 16/12/2025.
//

import SwiftUI

fileprivate let mealTimeFormatter: DateFormatter = {
    let df = DateFormatter()
    df.timeStyle = .short
    return df
}()

struct MealsListSection: View {
    let dayLog: DayLog
    let meals: [Meal]
    let onSelectMeal: (Meal) -> Void

 
    private var sectionOrder: [MealTimingTag] {
       
        if dayLog.isTrainingDay == false { return [.restDay] }
        return [.preWorkout, .postWorkout, .otherOnTrainingDay]
    }

    private var grouped: [MealTimingTag: [Meal]] {
        Dictionary(grouping: meals) { meal in
            meal.timingTag(
                relativeTo: dayLog.sessionStart,
                isTrainingDay: dayLog.isTrainingDay
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if meals.isEmpty {
                Text("No meals logged for the day...Start logging some to track the fuel for your workouts. 😀")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding()
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            } else {
                ForEach(sectionOrder, id: \.self) { tag in
                    let items = (grouped[tag] ?? []).sorted { $0.loggedAt < $1.loggedAt }

                    if !items.isEmpty {
                        TimingSectionHeader(tag: tag, count: items.count)

                        VStack(spacing: 14) {
                            ForEach(items) { meal in
                                Button {
                                    onSelectMeal(meal)
                                } label: {
                                    MealRow(dayLog: dayLog, meal: meal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct MealRow: View {
    let dayLog: DayLog
    let meal: Meal
    
    // Compute the timing tag once
    private var timingTag: MealTimingTag {
        meal.timingTag(
            relativeTo: dayLog.sessionStart,
            isTrainingDay: dayLog.isTrainingDay
        )
    }
    private var tagText: String { timingTag.chipText }
    private var tagColor: Color { timingTag.color }

    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            
            // HStack row for description and time
            HStack(alignment: .center) {
                Text(meal.description.truncated(to: 30, addEllipsis: true))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.primary)
                    .truncationMode(.tail)
                    .frame(maxWidth: 250, alignment: .leading)
                Spacer()
                Text(mealTimeFormatter.string(from: meal.loggedAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
    
            HStack(alignment: .center, spacing: 8) {
                // HStack for calories
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(Color.orange.opacity(0.7))
                    Text("\(Int(meal.macros.calories))")
                        .font(.callout).bold()
                }
                Text("•")
                HStack(spacing: 4) {
                    Text("P")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.green.opacity(0.8))
                    Text("\(Int(meal.macros.protein))")
                        .font(.callout).bold()
                }
                Text("•")
                HStack(spacing: 4) {
                    Text("C")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.orange.opacity(0.8))
                    Text("\(Int(meal.macros.carbs))")
                        .font(.callout).bold()
                }
                Text("•")
                HStack(spacing: 4) {
                    Text("F")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.cyan)
                    Text("\(Int(meal.macros.fat))")
                        .font(.callout).bold()
                }
            }
            
           
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 8)
        .shadow(color: .black.opacity(0.03), radius: 2,  x: 0, y: 1)
    }
}

private struct TimingSectionHeader: View {
    let tag: MealTimingTag
    let count: Int

    var body: some View {
        HStack(spacing: 10) {
            Text(tag.emoji)
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 2) {
                Text(tag.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("\(count) meal\(count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
             
            }

            Spacer()

//            // Small chip on the right
//            Text(tag.chipText)
//                .font(.system(size: 12, weight: .medium))
//                .foregroundStyle(tag.color)
//                .padding(.vertical, 4)
//                .padding(.horizontal, 10)
//                .background(tag.color.opacity(0.12), in: Capsule())
        }
        .padding(.top, 6)
        .padding(.horizontal, 4)
    }
}


#Preview {
    let log = DayLog.demoTrainingDay
     let meals = Meal.demoMeals(forTrainingDay: log)
    
    ZStack {
        AppBackground()
        MealsListSection(dayLog: log, meals: meals, onSelectMeal: { _ in print("")})
    }
}
