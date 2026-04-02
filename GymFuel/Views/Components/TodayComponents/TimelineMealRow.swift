//
//  TimelineMealRow.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/01/2026.
//

import SwiftUI



struct TimelineMealRow: View {
    let meal: Meal
    let tag: MealTimingTag

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: meal.loggedAt)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Text(meal.description.truncated(to: 25, addEllipsis: true))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(timeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.fuelOrange)
                    Text("\(Int(meal.macros.calories)) cal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Text("P:")
                        .font(.caption)
                        .foregroundStyle(Color.green.opacity(0.8))
                    Text("\(Int(meal.macros.protein))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Text("C:")
                        .font(.caption)
                        .foregroundStyle(Color.orange.opacity(0.8))
                    Text("\(Int(meal.macros.carbs))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Text("F:")
                        .font(.caption)
                        .foregroundStyle(Color.cyan)
                    Text("\(Int(meal.macros.fat))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}


#Preview {
    ZStack {
        AppBackground()
        TimelineMealRow(meal: Meal.demoMeals(forTrainingDay: DayLog.demoTrainingDay)[0], tag: .postWorkout)
    }
}
