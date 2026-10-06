//
//  WeightTrendCard.swift
//  GymFuel
//

import SwiftUI

/// Weight over time: what the scale said.
///
/// Built in the Circa language rather than the legacy stats idiom, per the rule
/// that every step after the design system builds its surfaces in the new
/// language — once, not twice.
///
/// **The card makes no recommendation.** It shows measurements and nothing else:
/// no rate, no target, no judgement of the number.
struct WeightTrendCard: View {
    let series: WeightSeries
    let unit: BodyWeightUnit
    let windowStart: Date
    let windowEnd: Date
    let onWeighIn: () -> Void
    /// Opens the Weight screen.
    var onOpen: (() -> Void)? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        CircaCard {
            VStack(alignment: .leading, spacing: Circa.Space.rowGap) {
                header

                if series.points.isEmpty {
                    emptyState
                } else {
                    // To the end of the window's last day, where that day's weigh-in sits.
                    WeightChart(series: series, unit: unit, domain: windowStart...windowEnd.addingTimeInterval(86_400))
                }

                Button("Weigh in", action: onWeighIn)
                    .buttonStyle(.circa(.secondary))

                if let onOpen {
                    Button("See all weigh-ins", action: onOpen)
                        .buttonStyle(.circa(.link, height: 32))
                }
            }
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
                latestValue
            }
        } else {
            HStack(alignment: .firstTextBaseline) {
                headerLabels
                Spacer(minLength: Circa.Space.rowGap)
                latestValue
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

    /// The last weigh-in in the window. A measurement, so no dotted rule.
    @ViewBuilder
    private var latestValue: some View {
        if let latest = series.latest {
            Text(BodyWeight.displayString(kilograms: latest.weightKg, unit: unit))
                .font(.circaMonoLarge)
                .monospacedDigit()
                .foregroundStyle(Color.circaInk)
        }
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

    // MARK: - Derived

    private var rangeLabel: String {
        let start = windowStart.formatted(.dateTime.month(.abbreviated).day())
        let end = windowEnd.formatted(.dateTime.month(.abbreviated).day())
        return "\(start) – \(end)"
    }
}

#if DEBUG
#Preview("Weigh-ins") {
    let calendar = DateKey.calendar()
    let today = Date()
    let weights: [Double] = [83.4, 83.1, 83.3, 82.8, 82.9, 82.5, 82.6]
    let weighIns = weights.enumerated().compactMap { offset, kg -> WeighIn? in
        guard let date = calendar.date(byAdding: .day, value: -(weights.count - offset) * 3, to: today) else { return nil }
        return WeighIn(recordedAt: date, weightKg: kg)
    }
    let series = WeightSeries(weighIns: weighIns)

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
