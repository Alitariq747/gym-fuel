//
//  MetricsPagerSection.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/01/2026.
//

import SwiftUI

struct MetricsPagerSection: View {
    let dayLog: DayLog
    let consumed: Macros
    let isLoading: Bool

    @State private var pageIndex: Int = 0
    @State private var cachedScoreLog: DayLog?

    private var displayDayLog: DayLog {
        if isLoading, dayLog.fuelScore == nil, let cachedScoreLog {
            return cachedScoreLog
        }
        return dayLog
    }

    var body: some View {
        VStack(spacing: 10) {
            TabView(selection: $pageIndex) {
                // PAGE 0: Fuel Score
                FuelScoreCard(dayLog: displayDayLog)
                    .tag(0)

                // PAGE 1: Macro rings
                MacroCardsSection(
                    targets: dayLog.macroTargets,
                    consumed: consumed
                )
                .tag(1)
            }
            // Important so TabView knows its height and swipes nicely inside ScrollView
            .frame(height: 290)
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom page indicators
            HStack(spacing: 6) {
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundStyle(pageIndex == 0 ? Color.primary : Color.secondary.opacity(0.3))

                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundStyle(pageIndex == 1 ? Color.primary : Color.secondary.opacity(0.3))
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 2)
        }
        .onAppear {
            if dayLog.fuelScore != nil {
                cachedScoreLog = dayLog
            }
        }
        .onChange(of: dayLog.fuelScore) { _, newScore in
            if newScore != nil {
                cachedScoreLog = dayLog
            }
        }
        .onChange(of: dayLog.id) { _, _ in
            if dayLog.fuelScore != nil {
                cachedScoreLog = dayLog
            }
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        MetricsPagerSection(
            dayLog: DayLog.demoTrainingDay,   // or your own dummy
            consumed: Macros(calories: 1200, protein: 90, carbs: 150, fat: 40),
            isLoading: false
        )
        .padding()
    }
}
