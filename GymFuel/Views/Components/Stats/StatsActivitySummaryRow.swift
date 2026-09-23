//
//  StatsActivitySummaryRow.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2025.
//

import SwiftUI

struct StatsActivitySummaryRow: View {
    let foodLogs: Int

    var body: some View {
        HStack(spacing: 12) {
            statTile(title: "Meals", value: "\(foodLogs)", symbol: "fork.knife")
        }
    }

    private func statTile(title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.headline)
                .frame(width: 34, height: 34)
                .foregroundStyle(Color.circaInk2)
                .background(Color.circaWell, in: Circle())
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(value)
                    .font(.title3.weight(.bold))
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.circaInk2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(Color.circaCard, in: RoundedRectangle(cornerRadius: Circa.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Circa.Radius.card, style: .continuous).stroke(Color.circaCardBorder, lineWidth: 1))
    }
}

#Preview {
    StatsActivitySummaryRow(foodLogs: 18)
        .padding()
}
