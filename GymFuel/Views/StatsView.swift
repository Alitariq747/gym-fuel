//
//  StatsView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2025.
//

import SwiftUI

private struct StatsLoadKey: Hashable {
    let weekStart: Date
    let targetMacros: Macros?
}

private struct PresentedCheckIn: Identifiable {
    let dueDateKey: String
    var id: String { dueDateKey }
}

struct StatsView: View {
    let profile: UserProfile
    /// The same target the Day screen shows — passed in, never recalculated
    /// here, so the two screens cannot disagree.
    let targetMacros: Macros?
    /// The phase in force. Decides when a weekly check-in is due.
    let phase: Phase?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: StatsViewModel
    @StateObject private var checkInViewModel: CheckInViewModel
    @EnvironmentObject private var healthWeightSync: HealthWeightSyncService
    @AppStorage(BodyWeightUnit.preferenceKey) private var weightUnitRawValue = BodyWeightUnit.kilograms.rawValue
    @State private var isWeighInPresented = false
    @State private var presentedCheckIn: PresentedCheckIn?
    /// Reports a saved weigh-in so the caller can refresh the profile it owns.
    /// Passed in rather than reached for through `@EnvironmentObject`: this view
    /// is itself presented as a sheet, and this is the one write path in the
    /// feature — not somewhere to depend on environment propagation.
    private let onWeighIn: (Double) -> Void
    /// Reports a check-in answer so the caller can move the phase it owns. Passed
    /// in for the same reason as `onWeighIn`.
    private let onCheckInDecision: (PhaseDecisionUpdate) -> Void
    init(
        profile: UserProfile,
        targetMacros: Macros?,
        phase: Phase? = nil,
        viewModel: StatsViewModel = StatsViewModel(),
        checkInViewModel: CheckInViewModel = CheckInViewModel(),
        onWeighIn: @escaping (Double) -> Void = { _ in },
        onCheckInDecision: @escaping (PhaseDecisionUpdate) -> Void = { _ in }
    ) {
        self.profile = profile
        self.targetMacros = targetMacros
        self.phase = phase
        self.onWeighIn = onWeighIn
        self.onCheckInDecision = onCheckInDecision
        _viewModel = StateObject(wrappedValue: viewModel)
        _checkInViewModel = StateObject(wrappedValue: checkInViewModel)
    }
    /// The open check-in, offered on the current week only.
    private var openCheckInDueDateKey: String? {
        guard !viewModel.canGoToNextWeek() else { return nil }
        return checkInViewModel.openDueDateKey(for: phase)
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

                if let dueDateKey = openCheckInDueDateKey {
                    CheckInCard {
                        checkInViewModel.reset()
                        presentedCheckIn = PresentedCheckIn(dueDateKey: dueDateKey)
                    }
                }

                // Outside the error branch on purpose: the weight trend loads
                // independently of the food stats, so neither failure should be
                // able to hide the other.
                if let window = viewModel.trendWindow() {
                    WeightTrendCard(
                        series: viewModel.weightTrend,
                        unit: BodyWeightUnit(rawValue: weightUnitRawValue) ?? .kilograms,
                        windowStart: window.start,
                        windowEnd: window.end,
                        onWeighIn: { isWeighInPresented = true },
                        onConnectHealth: showsHealthPrompt ? { Task { await connectHealth() } } : nil
                    )
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 12) {
                        StatsStreakCard(snapshot: snapshot)
                        StatsActivitySummaryRow(foodLogs: snapshot.foodLogsThisWeek)
                        CaloriesStatsCard(snapshot: snapshot)
                        macroSection
                    }
                }
            }
            .padding()
        }
        // Keyed on the target too: a weigh-in here changes it, and the macro
        // numbers should follow without switching weeks.
        .task(id: StatsLoadKey(weekStart: viewModel.selectedWeekStart, targetMacros: targetMacros)) {
            await viewModel.loadStats(userId: profile.id, targetMacros: targetMacros)
        }
        .task(id: viewModel.selectedWeekStart) {
            await viewModel.loadWeightTrend(userId: profile.id)
        }
        // A new phase starts its check-ins again from its own first day.
        .task(id: phase?.startDateKey) {
            await checkInViewModel.loadLatest(userId: profile.id)
        }
        .sheet(item: $presentedCheckIn) { checkIn in
            CheckInView(
                userId: profile.id,
                profile: profile,
                phase: phase,
                dueDateKey: checkIn.dueDateKey,
                viewModel: checkInViewModel,
                onDecision: onCheckInDecision
            )
        }
        .sheet(isPresented: $isWeighInPresented) {
            NavigationStack {
                EditWeightSheet(
                    userId: profile.id,
                    initialWeightKg: viewModel.weightTrend.latest?.weightKg ?? profile.weightKg,
                    onWeighIn: { kg in
                        onWeighIn(kg)
                        Task { await viewModel.loadWeightTrend(userId: profile.id) }
                    }
                )
            }
        }
    }

    /// Offered only while Health can supply weigh-ins and has not been asked to.
    private var showsHealthPrompt: Bool {
        healthWeightSync.isAvailable && !healthWeightSync.isConnected
    }

    /// Same two follow-ups the manual weigh-in already runs — reflect the weight
    /// in the caller's profile, then redraw the chart — so an import lands
    /// without closing the sheet.
    private func connectHealth() async {
        if let kg = await healthWeightSync.connect(userId: profile.id) {
            onWeighIn(kg)
        }
        await viewModel.loadWeightTrend(userId: profile.id)
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
