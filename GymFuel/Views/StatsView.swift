//
//  StatsView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2025.
//

import SwiftUI

struct StatsView: View {
    let profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: StatsViewModel
    private let macroTargetCalculator = MacroTargetCalculator()
    init(profile: UserProfile, viewModel: StatsViewModel = StatsViewModel()) {
        self.profile = profile
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    private var targetMacros: Macros? {
        macroTargetCalculator.targetMacros(for: profile)
    }
    private var snapshot: StatsSnapshot {
        viewModel.snapshot
    }
    private var weekLabel: String {
        guard let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: viewModel.selectedWeekStart) else {
            return viewModel.selectedWeekStart.formatted(.dateTime.month(.abbreviated).day())
        }
        return "\(viewModel.selectedWeekStart.formatted(.dateTime.month(.abbreviated).day())) - \(weekEnd.formatted(.dateTime.month(.abbreviated).day()))"
    }
    private var proteinTarget: Double? {
        snapshot.dailyStats.compactMap(\.targetProtein).first
    }
    private var carbsTarget: Double? {
        snapshot.dailyStats.compactMap(\.targetCarbs).first
    }
    private var fatTarget: Double? {
        snapshot.dailyStats.compactMap(\.targetFat).first
    }
    private var macroWeekdayLabels: [String] {
        snapshot.dailyStats.map { $0.date.formatted(.dateTime.weekday(.narrow)) }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                topControlsRow
                StatsWeekPicker(
                    weekLabel: weekLabel,
                    canGoNext: viewModel.canGoToNextWeek(),
                    onPrevious: { viewModel.goToPreviousWeek() },
                    onNext: { viewModel.goToNextWeek() }
                )

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 12) {
                        StatsStreakCard(snapshot: snapshot)
                        StatsActivitySummaryRow(
                            foodLogs: snapshot.foodLogsThisWeek,
                            workoutLogs: snapshot.workoutLogsThisWeek
                        )
                        CaloriesStatsCard(snapshot: snapshot)
                        macroSection
                    }
                }
            }
            .padding()
        }
        .task(id: viewModel.selectedWeekStart) {
            await viewModel.loadStats(userId: profile.id, targetMacros: targetMacros)
        }
    }

    private var topControlsRow: some View {
        HStack {
            if viewModel.isLoading {
                ProgressView()
                    .tint(Color.fuelOrange)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color(.secondarySystemBackground), in: Circle())
                    .overlay(Circle().stroke(Color.black.opacity(0.05), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        }
    }

    private var macroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Macros")
                    .font(.headline.weight(.bold))
            }
            if let proteinTarget {
                MacroMiniBarRow(
                    title: "Protein",
                    values: snapshot.dailyStats.map(\.protein),
                    labels: macroWeekdayLabels,
                    average: snapshot.averageProtein,
                    target: proteinTarget,
                    color: Color.fuelGreen
                )
                Divider()
            }
            if let carbsTarget {
                MacroMiniBarRow(
                    title: "Carbs",
                    values: snapshot.dailyStats.map(\.carbs),
                    labels: macroWeekdayLabels,
                    average: snapshot.averageCarbs,
                    target: carbsTarget,
                    color: Color.fuelBlue.opacity(0.8)
                )
                Divider()
            }
            if let fatTarget {
                MacroMiniBarRow(
                    title: "Fat",
                    values: snapshot.dailyStats.map(\.fat),
                    labels: macroWeekdayLabels,
                    average: snapshot.averageFat,
                    target: fatTarget,
                    color: Color.fuelOrange.opacity(0.75)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(statsCardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(statsCardStroke, lineWidth: 1))
        .shadow(color: statsCardShadow, radius: 12, y: 6)
    }

    private var statsCardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }

    private var statsCardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)
    }

    private var statsCardShadow: Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.05)
    }

}

private struct MacroMiniBarRow: View {
    let title: String
    let values: [Double]
    let labels: [String]
    let average: Double
    let target: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption.weight(.bold))
                Spacer()
                Text("Avg \(Int(average.rounded()))g · Target \(Int(target))g")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    VStack(spacing: 6) {
                        GeometryReader { proxy in
                            let ratio = target > 0 ? min(value / target, 1.15) : 0
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color(.tertiarySystemFill))
                                .overlay(alignment: .bottom) {
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(value > target ? Color.fuelRed.opacity(0.8) : color)
                                        .frame(height: value > 0 ? max(5, proxy.size.height * ratio / 1.15) : 0)
                                }
                        }
                        Text(labels.indices.contains(index) ? labels[index] : "")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                }
            }
        }
    }
}
