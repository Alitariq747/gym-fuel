//
//  InsightsView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/01/2026.
//

import SwiftUI

struct InsightsView: View {
    @StateObject private var viewModel: WeeklyInsightsViewModel
    @Environment(\.colorScheme) private var colorScheme

    init(profile: UserProfile) {
        _viewModel = StateObject(
            wrappedValue: WeeklyInsightsViewModel(profile: profile)
        )
    }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 16) {
                    WeekPickerView(
                        selectedWeekStart: Binding(
                            get: { viewModel.selectedWeekStart },
                            set: { newWeekStart in
                                viewModel.updateWeekStart(to: newWeekStart)
                            }
                        )
                    )

                    if viewModel.isLoading {
                        ProgressView("Loading week…")
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                    
                    //Stats VStack
                    VStack {
                        MacroStats(averageFuelScore: viewModel.averageFuelScore, trainingDaysPlanned: viewModel.trainingDaysPlanned, trainingDaysCompleted: viewModel.trainingDaysLogged, restDays: viewModel.restDays, highScoreDays: viewModel.highScoreDays)
                        
                        // Per day data
                        VStack(spacing: 5) {
                            ForEach(viewModel.dayRows) { row in
                                DayFuelStatsRow(row: row)
                                Divider()
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemBackground)))
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.08), radius: colorScheme == .dark ? 18 : 12, x: 0, y: colorScheme == .dark ? 10 : 6)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fuel score trend")
                            .font(.headline)

                        WeeklyFuelScoreChart(points: viewModel.dailyFuelScores)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                    
                    WeeklyMacroOverviewCard(overview: viewModel.weeklyMacroOverview)
                }
                .padding()
            }
        }
        .task {
            await viewModel.loadCurrentWeek()
        }
    }
}

#Preview {
    InsightsView(profile: dummyProfile)  
}
