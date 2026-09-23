//
//  StatsWeekPicker.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2025.
//

import SwiftUI

struct StatsWeekPicker: View {
    let weekLabel: String
    let canGoNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onDateTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Spacer()
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                    .background(Color.circaCard, in: Circle())
                    
            }
            Button(action: onDateTap) {
                HStack(spacing: 4) {
                    Text(weekLabel)
                    Image(systemName: "calendar")
                }
                .font(.circaRow.weight(.semibold))
                .foregroundStyle(Color.circaInk)
                .frame(minHeight: Circa.minHitTarget)
            }
            .accessibilityLabel("Choose date and Day or Week view")
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                    .background(Color.circaCard, in: Circle())
            }
            .disabled(!canGoNext)
            Spacer()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StatsWeekPicker(
        weekLabel: "May 4 - May 10",
        canGoNext: false,
        onPrevious: {},
        onNext: {},
        onDateTap: {}
    )
    .padding()
}
