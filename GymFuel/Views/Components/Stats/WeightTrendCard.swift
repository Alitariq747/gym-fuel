//
//  WeightTrendCard.swift
//  GymFuel
//

import Charts
import SwiftUI

/// Weight over time: what the scale said, and the smoothed line through it.
///
/// Built in the Circa language rather than the legacy stats idiom, per the rule
/// that every step after the design system builds its surfaces in the new
/// language — once, not twice.
///
/// **The card makes no recommendation.** It shows a measurement and a disclosed
/// estimate, and nothing else: no rate, no target, no judgement of the number.
/// Coaching language arrives with the check-in, alongside its citations.
///
/// Swift Charts rather than a hand-drawn `Path`: every other chart in this app is
/// a fixed seven-column bar layout with no scale and no date mapping, and a
/// weight series is a continuous domain with arbitrary gaps. It is a system
/// framework, so it costs no dependency, and it brings date-axis scaling, RTL
/// mirroring, Dynamic Type on axis labels and per-mark VoiceOver with it.
struct WeightTrendCard: View {
    let series: WeightTrendSeries
    let unit: BodyWeightUnit
    let windowStart: Date
    let windowEnd: Date
    let onWeighIn: () -> Void
    /// Non-nil only while Apple Health is available and not yet connected, so
    /// the prompt removes itself the moment it is used.
    var onConnectHealth: (() -> Void)? = nil

    @ScaledMetric(relativeTo: .body) private var chartHeight: CGFloat = 160
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isSourcesPresented = false

    var body: some View {
        CircaCard {
            VStack(alignment: .leading, spacing: Circa.Space.rowGap) {
                header

                if series.points.isEmpty {
                    emptyState
                } else {
                    chart
                }

                if let prompt = insufficientDataPrompt {
                    Text(prompt)
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaInk3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button("Weigh in", action: onWeighIn)
                    .buttonStyle(.circa(.secondary))

                if let onConnectHealth {
                    // The cheapest possible second weigh-in: a scale that
                    // already writes to Health.
                    Button("Sync from Apple Health", action: onConnectHealth)
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

    // MARK: - Chart

    private var chart: some View {
        Chart {
            // Measurements: solid. These are facts.
            ForEach(series.points) { point in
                PointMark(
                    x: .value("Day", point.date),
                    y: .value("Weight", displayValue(point.weightKg))
                )
                .symbolSize(22)
                .foregroundStyle(Color.circaInk3)
                .accessibilityLabel(accessibilityDate(point.date))
                .accessibilityValue(BodyWeight.displayString(kilograms: point.weightKg, unit: unit))
            }

            // Trend: dotted. This is an estimate.
            if series.hasTrend {
                ForEach(series.points) { point in
                    LineMark(
                        x: .value("Day", point.date),
                        y: .value("Trend", displayValue(point.trendKg)),
                        series: .value("Series", "trend")
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(Color.circaAccent)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.01, 4]))
                    .accessibilityHidden(true)
                }
            }
        }
        // Without an explicit x domain, three points stretch across the full
        // width and misrepresent how often the user actually weighed in.
        .chartXScale(domain: windowStart...windowEnd)
        // Without an explicit y domain, Swift Charts includes zero and every
        // real variation collapses into a flat line.
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) {
                AxisValueLabel()
                    .font(.circaMono)
                    .foregroundStyle(Color.circaInk3)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) {
                AxisGridLine().foregroundStyle(Color.circaBarTrack)
                AxisValueLabel()
                    .font(.circaMono)
                    .foregroundStyle(Color.circaInk3)
            }
        }
        .frame(height: chartHeight)
        .accessibilityLabel("Weight trend, \(rangeLabel)")
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

    private func displayValue(_ kilograms: Double) -> Double {
        unit == .kilograms ? kilograms : BodyWeight.pounds(fromKilograms: kilograms)
    }

    private var trendText: String {
        guard let latest = series.latest else { return "" }
        return BodyWeight.displayString(kilograms: latest.trendKg, unit: unit)
    }

    private var yDomain: ClosedRange<Double> {
        let values = series.points.flatMap { [displayValue($0.weightKg), displayValue($0.trendKg)] }
        guard let low = values.min(), let high = values.max() else { return 0...1 }

        let padding = unit == .kilograms ? 1.0 : BodyWeight.pounds(fromKilograms: 1)
        return (low - padding)...(high + padding)
    }

    private var rangeLabel: String {
        let start = windowStart.formatted(.dateTime.month(.abbreviated).day())
        let end = windowEnd.formatted(.dateTime.month(.abbreviated).day())
        return "\(start) – \(end)"
    }

    private func accessibilityDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).day())
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
