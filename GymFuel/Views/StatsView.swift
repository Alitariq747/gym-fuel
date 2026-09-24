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
    @StateObject private var viewModel: StatsViewModel
    @EnvironmentObject private var healthWeightSync: HealthWeightSyncService
    @AppStorage(BodyWeightUnit.preferenceKey) private var weightUnitRawValue = BodyWeightUnit.kilograms.rawValue
    @State private var isWeighInPresented = false
    @State private var isWeightPresented = false
    @State private var isDatePickerPresented = false
    @State private var selectedDate: Date
    @State private var pendingDayDate: Date?
 
    private let onWeighIn: (Double) -> Void
    private let onSelectedDateChange: (Date) -> Void
    private let onShowDay: (Date) -> Void
    init(
        profile: UserProfile,
        selectedDate: Date,
        viewModel: StatsViewModel? = nil,
        onWeighIn: @escaping (Double) -> Void = { _ in },
        onSelectedDateChange: @escaping (Date) -> Void,
        onShowDay: @escaping (Date) -> Void
    ) {
        self.profile = profile
        self.onWeighIn = onWeighIn
        self.onSelectedDateChange = onSelectedDateChange
        self.onShowDay = onShowDay
        _selectedDate = State(initialValue: selectedDate)
        _viewModel = StateObject(wrappedValue: viewModel ?? StatsViewModel(now: selectedDate))
    }
    private var targetMacros: Macros? {
        profile.savedTargets
    }
    private var snapshot: StatsSnapshot {
        viewModel.snapshot
    }
    private var weekTitle: String {
        WeekCopy.title(weekStart: viewModel.selectedWeekStart)
    }
    private var weekLabel: String {
        WeekCopy.range(weekStart: viewModel.selectedWeekStart)
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
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StatsWeekPicker(
                    title: weekTitle,
                    rangeLabel: weekLabel,
                    isLoading: viewModel.isLoading,
                    canGoNext: viewModel.canGoToNextWeek(),
                    onPrevious: { moveWeek(by: -1) },
                    onNext: { moveWeek(by: 1) },
                    onDateTap: { isDatePickerPresented = true }
                )
                .padding(.horizontal, Circa.Space.screenMargin)

                VStack(spacing: 14) {
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
                            onConnectHealth: showsHealthPrompt ? { Task { await connectHealth() } } : nil,
                            onOpen: { isWeightPresented = true }
                        )
                    }

                    if let errorMessage = viewModel.errorMessage {
                        CircaCard(.sunken) {
                            Text(errorMessage)
                                .font(.circaBody)
                                .foregroundStyle(Color.circaInk2)
                        }
                    } else {
                        CaloriesStatsCard(snapshot: snapshot)
                        macroSection
                        StatsMealsWrittenTile(foodLogs: snapshot.foodLogsThisWeek)
                    }
                }
                .padding(.horizontal, Circa.Space.screenMarginWide)
            }
            .padding(.vertical, 16)
        }
        .circaPaper()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Color.circaInk)
                }
                .accessibilityLabel("Close")
            }
        }
        .task(id: viewModel.selectedWeekStart) {
            await viewModel.loadStats(userId: profile.id, targetMacros: targetMacros)
        }
        .task(id: viewModel.selectedWeekStart) {
            await viewModel.loadWeightTrend(userId: profile.id)
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
        .sheet(isPresented: $isDatePickerPresented, onDismiss: {
            if let date = pendingDayDate {
                pendingDayDate = nil
                onShowDay(date)
            }
        }) {
            DayWeekPickerSheet(date: selectedDate, scale: .week) { date, scale in
                if scale == .day {
                    pendingDayDate = date
                } else {
                    selectDate(date)
                }
            }
        }
        .navigationDestination(isPresented: $isWeightPresented) {
            WeightView()
        }
        // A weigh-in deleted there must not linger on the card.
        .onChange(of: isWeightPresented) { _, isPresented in
            if !isPresented { Task { await viewModel.loadWeightTrend(userId: profile.id) } }
        }
    }

    private func moveWeek(by offset: Int) {
        guard let candidate = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: selectedDate) else { return }
        selectDate(min(candidate, .now))
    }

    private func selectDate(_ date: Date) {
        selectedDate = Calendar.current.startOfDay(for: date)
        viewModel.selectWeek(containing: selectedDate)
        onSelectedDateChange(selectedDate)
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

    /// Daily average against target, from the `Week` artboard.
    ///
    /// `Week · day 2` has no such card, and this follows it: a "daily average"
    /// over two days is the same overclaim `CaloriesStatsCard`'s gate exists to
    /// avoid, so the whole card waits for the fourth day with food.
    @ViewBuilder
    private var macroSection: some View {
        if snapshot.hasEnoughDaysForAverages {
            CircaCard {
                VStack(alignment: .leading, spacing: 15) {
                    CircaSectionLabel("Daily average vs target")
                    VStack(alignment: .leading, spacing: 13) {
                        if let proteinTarget {
                            macroRow("Protein", average: snapshot.averageProtein, target: proteinTarget)
                        }
                        if let carbsTarget {
                            macroRow("Carbs", average: snapshot.averageCarbs, target: carbsTarget)
                        }
                        if let fatTarget {
                            macroRow("Fat", average: snapshot.averageFat, target: fatTarget)
                        }
                    }
                }
            }
        }
    }

    private func macroRow(_ title: String, average: Double, target: Double) -> some View {
        let value = Int(average.rounded())
        let goal = Int(target.rounded())
        let fraction = goal > 0 ? min(max(Double(value) / Double(goal), 0), 1) : 0

        return VStack(alignment: .leading, spacing: 6) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(title)
                        .font(.circaRow)
                        .foregroundStyle(Color.circaInk)
                    Spacer(minLength: 8)
                    macroValue(value, of: goal)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.circaRow)
                        .foregroundStyle(Color.circaInk)
                    macroValue(value, of: goal)
                }
            }
            // Clamped rather than recoloured: the calorie chart's ochre marks a
            // defined range, and there is no such band here to be outside of.
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.circaBarTrack)
                    Capsule().fill(Color.circaInk).frame(width: proxy.size.width * fraction)
                }
            }
            .frame(height: 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), averaging \(value) of \(goal) grams a day")
    }

    private func macroValue(_ value: Int, of target: Int) -> some View {
        HStack(spacing: 4) {
            Text(value.formatted())
                .foregroundStyle(Color.circaInk2)
            Text("/ \(target.formatted()) g")
                .foregroundStyle(Color.circaInk3)
        }
        .font(.circaMono)
        .monospacedDigit()
        .fixedSize(horizontal: false, vertical: true)
    }
}
