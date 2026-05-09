//
//  StatsStreakCard.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2025.
//

import SwiftUI

struct StatsStreakCard: View {
    let snapshot: StatsSnapshot

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Current streak")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(snapshot.currentStreakDays)")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                    Text(snapshot.currentStreakDays == 1 ? "day" : "days")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Text("\(snapshot.daysLoggedThisWeek) of 7 days logged")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                weeklyDayIndicators
            }
            Spacer()
            Image(systemName: "flame.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.fuelOrange)
                .frame(width: 66, height: 66)
                .background(Color.fuelOrange.opacity(0.14), in: Circle())
        }
        .padding(18)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }

    private var weeklyDayIndicators: some View {
        HStack(spacing: 6) {
            ForEach(snapshot.dailyStats) { day in
                let hasLogged = day.caloriesEaten > 0 || day.caloriesBurned > 0 || day.protein > 0 || day.carbs > 0 || day.fat > 0
                Text(day.date.formatted(.dateTime.weekday(.narrow)))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(hasLogged ? Color.white : Color.secondary)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(hasLogged ? Color.fuelGreen.opacity(0.5) : Color(.tertiarySystemFill))
                    )
            }
        }
        .padding(.top, 4)
    }
}

#Preview {
    StatsStreakCard(snapshot: .empty)
        .padding()
}
