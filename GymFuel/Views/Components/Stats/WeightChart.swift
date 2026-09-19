//
//  WeightChart.swift
//  GymFuel
//

import Charts
import SwiftUI

/// Weight over time: the weigh-ins, the trend through them and, when given one,
/// the plan line and the goal. Shared by the Week card, the Weight screen and the
/// onboarding plan screen, so no two of them draw weight differently.
///
/// Swift Charts rather than a hand-drawn `Path`: every other chart in this app is
/// a fixed seven-column bar layout with no scale and no date mapping, and a
/// weight series is a continuous domain with arbitrary gaps. It is a system
/// framework, so it costs no dependency, and it brings date-axis scaling, RTL
/// mirroring, Dynamic Type on axis labels and per-mark VoiceOver with it.
struct WeightChart: View {
    let series: WeightTrendSeries
    let unit: BodyWeightUnit
    let domain: ClosedRange<Date>
    var plan: WeightPlan? = nil

    /// Estimates are dotted — `design.md` rule 1. The trend and the plan are both
    /// estimates, so both wear it, and the ink tells them apart.
    private static let dottedStroke = StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.01, 4])
    /// How close the goal must sit to what is drawn before the chart draws it.
    /// Further out, fitting it in would flatten every weigh-in into a line.
    private static let goalReachKg: Double = 2

    @ScaledMetric(relativeTo: .body) private var chartHeight: CGFloat = 160
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            chart
            if plan != nil {
                legend
            }
        }
    }

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
                    .lineStyle(Self.dottedStroke)
                    .accessibilityHidden(true)
                }
            }

            // Plan: dotted too, in the certainty rule's grey. Where the plan
            // heads, not something measured.
            ForEach(planPoints) { point in
                LineMark(
                    x: .value("Day", point.date),
                    y: .value("Plan", displayValue(point.weightKg)),
                    series: .value("Series", "plan")
                )
                .foregroundStyle(Color.circaDotted)
                .lineStyle(Self.dottedStroke)
                .accessibilityHidden(true)
            }

            if let goalKg = visibleGoalKg {
                RuleMark(y: .value("Goal", displayValue(goalKg)))
                    .foregroundStyle(Color.circaInk3)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal \(BodyWeight.displayString(kilograms: goalKg, unit: unit))")
                            .font(.circaMono)
                            .foregroundStyle(Color.circaInk3)
                    }
                    .accessibilityHidden(true)
            }
        }
        // Without an explicit x domain, three points stretch across the full
        // width and misrepresent how often the user actually weighed in.
        .chartXScale(domain: domain)
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
        .accessibilityLabel(plan == nil ? "Weight trend, \(rangeLabel)" : "Weight trend and plan, \(rangeLabel)")
    }

    // MARK: - Legend

    /// Names the two dotted lines, which differ only in ink. Stacks at
    /// accessibility sizes rather than truncating — `design.md` rule 8.
    private var legend: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 14))

        return layout {
            legendItem("Weigh-ins", mark: Circle().fill(Color.circaInk3).frame(width: 5, height: 5))
            legendItem("Trend", mark: dottedSample(Color.circaAccent))
            legendItem("Plan", mark: dottedSample(Color.circaDotted))
        }
        .accessibilityHidden(true)
    }

    private func legendItem(_ title: String, mark: some View) -> some View {
        HStack(spacing: 5) {
            mark
            Text(title)
                .font(.circaMono)
                .foregroundStyle(Color.circaInk3)
        }
    }

    private func dottedSample(_ color: Color) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 1, y: 3))
            path.addLine(to: CGPoint(x: 15, y: 3))
        }
        .stroke(color, style: Self.dottedStroke)
        .frame(width: 16, height: 6)
    }

    // MARK: - Derived

    private var planPoints: [WeightPlanPoint] {
        plan?.points(from: domain.lowerBound, through: domain.upperBound) ?? []
    }

    /// Every weight drawn, in kilograms, before the goal is considered.
    private var drawnKilograms: [Double] {
        series.points.flatMap { [$0.weightKg, $0.trendKg] } + planPoints.map(\.weightKg)
    }

    /// The goal, when it sits within reach of what is drawn (decided 19 September).
    /// The Weight screen states the goal in words either way.
    private var visibleGoalKg: Double? {
        guard let goalKg = plan?.goalWeightKg,
              let low = drawnKilograms.min(),
              let high = drawnKilograms.max(),
              (low - Self.goalReachKg)...(high + Self.goalReachKg) ~= goalKg
        else { return nil }
        return goalKg
    }

    private var yDomain: ClosedRange<Double> {
        let values = (drawnKilograms + [visibleGoalKg].compactMap { $0 }).map(displayValue)
        guard let low = values.min(), let high = values.max() else { return 0...1 }

        let padding = unit == .kilograms ? 1.0 : BodyWeight.pounds(fromKilograms: 1)
        return (low - padding)...(high + padding)
    }

    private func displayValue(_ kilograms: Double) -> Double {
        unit == .kilograms ? kilograms : BodyWeight.pounds(fromKilograms: kilograms)
    }

    private var rangeLabel: String {
        let start = domain.lowerBound.formatted(.dateTime.month(.abbreviated).day())
        let end = domain.upperBound.formatted(.dateTime.month(.abbreviated).day())
        return "\(start) – \(end)"
    }

    private func accessibilityDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).day())
    }
}

#if DEBUG
#Preview("With a plan") {
    let calendar = DateKey.calendar()
    let today = Date()
    let weights: [Double] = [86.1, 85.8, 85.9, 85.4, 85.5, 85.0, 85.2, 84.7, 84.8, 84.4]
    let weighIns = weights.enumerated().compactMap { offset, kg -> WeighIn? in
        guard let date = calendar.date(byAdding: .day, value: -(weights.count - offset) * 4, to: today) else { return nil }
        return WeighIn(recordedAt: date, weightKg: kg)
    }
    let planStart = calendar.date(byAdding: .day, value: -40, to: today) ?? today
    let domainStart = calendar.date(byAdding: .day, value: -90, to: today) ?? today
    let domainEnd = calendar.date(byAdding: .day, value: 28, to: today) ?? today

    return CircaCard {
        WeightChart(
            series: WeightTrendCalculator().series(from: weighIns),
            unit: .kilograms,
            domain: domainStart...domainEnd,
            plan: WeightPlan(goal: .cut, startDate: planStart, startWeightKg: 86, goalWeightKg: 83, weeklyChangeKg: -0.43)
        )
    }
    .padding()
    .circaPaper()
}
#endif
