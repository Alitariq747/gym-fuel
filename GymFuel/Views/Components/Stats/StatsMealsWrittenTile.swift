//
//  StatsMealsWrittenTile.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2025.
//

import SwiftUI

/// What the week holds, counted. From the `Week` artboard's lower tiles — the
/// pair it belonged to lost its day-streak half in Step 7t, which leaves this
/// one spanning the row.
///
/// Habit, not performance: a count with no target beside it and nothing to pass
/// or fail.
struct StatsMealsWrittenTile: View {
    let foodLogs: Int

    var body: some View {
        CircaCard(
            inset: EdgeInsets(top: 16, leading: Circa.Space.cardInset,
                              bottom: 16, trailing: Circa.Space.cardInset)
        ) {
            VStack(alignment: .leading, spacing: 5) {
                Text(foodLogs.formatted())
                    .font(.circaMonoLarge)
                    .monospacedDigit()
                CircaSectionLabel(foodLogs == 1 ? "Meal written" : "Meals written")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(foodLogs) \(foodLogs == 1 ? "meal" : "meals") written this week")
    }
}

#Preview {
    VStack(spacing: 12) {
        StatsMealsWrittenTile(foodLogs: 22)
        StatsMealsWrittenTile(foodLogs: 1)
    }
    .padding()
    .circaPaper()
}
