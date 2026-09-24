//
//  WeightTrendCard.swift
//  GymFuel
//

import SwiftUI

/// Weight over time: what the scale said, and the smoothed line through it.
///
/// Built in the Circa language rather than the legacy stats idiom, per the rule
/// that every step after the design system builds its surfaces in the new
/// language — once, not twice.
///
/// **The card makes no recommendation.** It shows a measurement and a disclosed
/// estimate, and nothing else: no rate, no target, no judgement of the number.
struct WeightTrendCard: View {
    let series: WeightTrendSeries
    let unit: BodyWeightUnit
    let windowStart: Date
    let windowEnd: Date
    let onWeighIn: () -> Void
    /// Opens the Weight screen.
    var onOpen: (() -> Void)? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isSourcesPresented = false

    var body: some View {
        CircaCard {
            VStack(alignment: .leading, spacing: Circa.Space.rowGap) {
                header

                if series.points.isEmpty {
                    emptyState
                } else {
                    WeightChart(series: series, unit: unit, domain: windowStart...windowEnd)
                }

                if let prompt = insufficientDataPrompt {
                    Text(prompt)
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaInk3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button("Weigh in", action: onWeighIn)
                    .buttonStyle(.circa(.secondary))

                if let onOpen {
                    Button("See weigh-ins and plan", action: onOpen)
                        .buttonStyle(.circa(.link, height: 32))
                }

                // One tap from the number to the method and its citations.
                Button("How the trend is calculated") { isSourcesPresented = true }
                    .buttonStyle(.circa(.link, height: 32))
            }
        }
        .sheet(isPresented: $isSourcesPresented) {
            NutritionSourcesView()
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        if dynamicTypeSize.isAccessibilitySize {
            // Right-aligned numbers beside wrapping text is the classic Dynamic
            // Type break, so the row goes vertical at accessibility sizes.
            VStack(alignment: .leading, spacing: 4) {
                headerLabels
                trendValue
            }
        } else {
            HStack(alignment: .firstTextBaseline) {
                headerLabels
                Spacer(minLength: Circa.Space.rowGap)
                trendValue
            }
        }
    }

    private var headerLabels: some View {
        VStack(alignment: .leading, spacing: 2) {
            CircaSectionLabel("Weight")
            Text(rangeLabel)
                .font(.circaMono)
                .foregroundStyle(Color.circaInk3)
        }
    }

    /// The trend is a smoothed value, so it carries the dotted certainty rule —
    /// the same mark that means "estimated" on a logged meal.
    ///
    /// Below the threshold this is `nil`, which draws the pending rule alone and
    /// reserves the exact height the number will occupy. When the third weigh-in
    /// lands, only the number appears: nothing jumps.
    private var trendValue: some View {
        CircaEstimate(
            series.hasTrend ? trendText : nil,
            certainty: series.hasTrend ? .estimated : .pending,
            font: .circaMonoLarge
        )
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "scalemass")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.circaInk3)
            Text("No weigh-ins yet")
                .font(.circaEntryTitle)
                .foregroundStyle(Color.circaInk)
            Text("Your weight moves day to day with water, food and salt. Weighing in regularly is what turns those numbers into a direction.")
                .font(.circaCaption)
                .foregroundStyle(Color.circaInk3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var insufficientDataPrompt: String? {
        guard !series.points.isEmpty, !series.hasTrend else { return nil }

        let remaining = WeightTrendCalculator.minimumPointsForTrend - series.points.count
        return remaining == 1
            ? "1 more weigh-in and your trend appears."
            : "\(remaining) more weigh-ins and your trend appears."
    }

    // MARK: - Derived

    private var trendText: String {
        guard let latest = series.latest else { return "" }
        return BodyWeight.displayString(kilograms: latest.trendKg, unit: unit)
    }

    private var rangeLabel: String {
        let start = windowStart.formatted(.dateTime.month(.abbreviated).day())
        let end = windowEnd.formatted(.dateTime.month(.abbreviated).day())
        return "\(start) – \(end)"
    }
}

#if DEBUG
#Preview("Trend") {
    let calendar = DateKey.calendar()
    let today = Date()
    let weights: [Double] = [83.4, 83.1, 83.3, 82.8, 82.9, 82.5, 82.6]
    let weighIns = weights.enumerated().compactMap { offset, kg -> WeighIn? in
        guard let date = calendar.date(byAdding: .day, value: -(weights.count - offset) * 3, to: today) else { return nil }
        return WeighIn(recordedAt: date, weightKg: kg)
    }
    let series = WeightTrendCalculator().series(from: weighIns)

    return ScrollView {
        WeightTrendCard(
            series: series,
            unit: .kilograms,
            windowStart: calendar.date(byAdding: .day, value: -30, to: today) ?? today,
            windowEnd: today,
            onWeighIn: {}
        )
        .padding()
    }
    .circaPaper()
}

#Preview("Empty") {
    ScrollView {
        WeightTrendCard(
            series: .empty,
            unit: .kilograms,
            windowStart: Date().addingTimeInterval(-90 * 86_400),
            windowEnd: Date(),
            onWeighIn: {}
        )
        .padding()
    }
    .circaPaper()
}
#endif
