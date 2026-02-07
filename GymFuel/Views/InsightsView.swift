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
    @Environment(\.dismiss) private var dismiss

    init(profile: UserProfile) {
        _viewModel = StateObject(
            wrappedValue: WeeklyInsightsViewModel(profile: profile)
        )
    }

    
    var body: some View {
        let isRefreshing = viewModel.isLoading && !viewModel.weekDayLogs.isEmpty

        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        if viewModel.isLoading {
                            UpdatingPill()
                                .transition(.opacity)
                        }
           


                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(10)
                                .background(Color(.systemBackground), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    WeekPickerView(
                        selectedWeekStart: Binding(
                            get: { viewModel.selectedWeekStart },
                            set: { newWeekStart in
                                viewModel.updateWeekStart(to: newWeekStart)
                            }
                        )
                    )
                    .animation(.easeInOut(duration: 0.15), value: isRefreshing)
                    .disabled(viewModel.isLoading)
                    

                    if let error = viewModel.errorMessage {
                        HStack(alignment: .center, spacing: 12) {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.leading)

                            Spacer()

                            Button("Retry") {
                                Task {
                                    await viewModel.loadWeek(for: viewModel.selectedWeekStart)
                                }
                            }
                            .font(.footnote.weight(.semibold))
                        }
                        .padding(.vertical, 6)
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
            .opacity(isRefreshing ? 0.65 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isRefreshing)
        }
        .task(id: viewModel.selectedWeekStart) {
            await viewModel.loadWeek(for: viewModel.selectedWeekStart)
        }
        .refreshable {
            await viewModel.loadWeek(for: viewModel.selectedWeekStart)
        }
    }
    
    private struct UpdatingPill: View {
        var body: some View {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .background(Color(.systemBackground), in: Circle())
            }

        }
    }

}

#Preview {
    InsightsView(profile: dummyProfile)  
}
