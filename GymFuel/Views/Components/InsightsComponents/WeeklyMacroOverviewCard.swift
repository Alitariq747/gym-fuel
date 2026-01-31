//
//  WeeklyMacroOverviewCard.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 26/01/2026.
//

import SwiftUI

struct WeeklyMacroOverviewCard: View {
    /// If nil -> show empty state.
    let overview: MacroPercentages?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if let overview {
                validContent(overview)
            } else {
                emptyContent
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.headline)

            Text("Macro Adherence")
                .font(.headline)

            Text("(Weekly Average)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    // MARK: - Valid state

    private func validContent(_ overview: MacroPercentages) -> some View {
        VStack(spacing: 10) {
            MacroLine(label: "Calories", pct: overview.caloriesPct, kind: .calories)
            Divider().opacity(0.6)

            MacroLine(label: "Protein",  pct: overview.proteinPct,  kind: .protein)
            Divider().opacity(0.6)

            MacroLine(label: "Carbs",    pct: overview.carbsPct,    kind: .carbs)
            Divider().opacity(0.6)

            MacroLine(label: "Fat",      pct: overview.fatPct,      kind: .fat)
        }
    }

    // MARK: - Empty state

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "fork.knife")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("No macro data for this week yet")
                        .font(.subheadline.weight(.semibold))

                    Text("Log your meals for a few days and we’ll show your weekly macro adherence here.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                EmptyChip(title: "Log meals")
                EmptyChip(title: "Hit targets")
                EmptyChip(title: "See trends")
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - MacroLine

private struct MacroLine: View {
    enum Kind { case calories, protein, carbs, fat }

    let label: String
    let pct: Double
    let kind: Kind

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {

            Text(label + ":")
                .font(.subheadline.weight(.semibold))
                .frame(width: 90, alignment: .leading)
            
            Spacer()

            Image(systemName: iconName)
                .foregroundStyle(statusColor)

            Text("\(pctRounded)%")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(statusColor)
                .frame(width: 52, alignment: .trailing)

            Text("of target")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }


    private var pctRounded: Int { Int(pct.rounded()) }


    private var statusColor: Color {
        let p = pct
        if (95...105).contains(p) { return .fuelGreen }
        if (85...95).contains(p) { return .fuelBlue }
        if (105...120).contains(p) { return .fuelOrange }
        return .fuelRed
    }

    private var iconName: String {
        let p = pct
        if (95...105).contains(p) { return "checkmark.circle.fill" }
        if p > 105 { return "arrow.up.circle.fill" }
        return "exclamationmark.triangle.fill"
    }
}

// MARK: - EmptyChip

private struct EmptyChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color(.secondarySystemBackground))
            )
            .foregroundStyle(.secondary)
    }
}

// MARK: - Previews

#Preview("Valid") {
    WeeklyMacroOverviewCard(
        overview: MacroPercentages(
            caloriesPct: 94,
            proteinPct: 108,
            carbsPct: 85,
            fatPct: 101
        )
    )
    .padding()
    .background(Color(.secondarySystemBackground))
}

#Preview("No data") {
    WeeklyMacroOverviewCard(overview: nil)
        .padding()
        .background(Color(.secondarySystemBackground))
}
