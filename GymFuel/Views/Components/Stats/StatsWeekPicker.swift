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

    var body: some View {
        HStack(spacing: 10) {
            Spacer()
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .padding(12)
                    .background(Color(.secondarySystemBackground),in: Circle())
                    
            }
            Text(weekLabel)
                .font(.headline.weight(.semibold))
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .padding(12)
                    .background(Color(.secondarySystemBackground),in: Circle())
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
        onNext: {}
    )
    .padding()
}
