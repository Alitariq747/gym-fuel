//
//  StatsStreakCard.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2025.
//

import SwiftUI

struct StatsStreakCard: View {
    let snapshot: StatsSnapshot
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var streakSize: CGFloat = 46

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Current streak")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.circaInk2)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(snapshot.currentStreakDays)")
                        .font(.system(size: streakSize, weight: .bold, design: .rounded))
                    Text(snapshot.currentStreakDays == 1 ? "day" : "days")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.circaInk2)
                }
                Text("\(snapshot.daysLoggedThisWeek) of 7 days logged")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color.circaInk2)
                if !dynamicTypeSize.isAccessibilitySize { weeklyDayIndicators }
            }
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.circaAccent)
                    .frame(width: 66, height: 66)
                    .background(Color.circaWell, in: Circle())
            }
        }
        .padding(18)
        .background(Color.circaCard, in: RoundedRectangle(cornerRadius: Circa.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Circa.Radius.card, style: .continuous).stroke(Color.circaCardBorder, lineWidth: 1))
    }

    private var weeklyDayIndicators: some View {
        HStack(spacing: 6) {
            ForEach(snapshot.dailyStats) { day in
                let hasLogged = day.caloriesEaten > 0 || day.protein > 0 || day.carbs > 0 || day.fat > 0
                Text(day.date.formatted(.dateTime.weekday(.narrow)))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(hasLogged ? Color.circaPaperTop : Color.circaInk2)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(hasLogged ? Color.circaInk : Color.circaSunken)
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
