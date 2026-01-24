//
//  MealParsingErrorView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 18/12/2025.
//

import SwiftUI

struct MealParsingErrorView: View {
    let message: String
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Icon + title
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.red)

                Text("We couldn’t estimate your meal")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Helpful hint
            Text("Try adjusting your description and run it again.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Primary action
            Button {
                onBack()
            } label: {
                Text("Back to description")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.liftEatsCoral)
                    )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.85))
        )
        .shadow(color: Color.black.opacity(0.16), radius: 18, x: 0, y: 10)
        .padding(.horizontal, 24)
    }
}


#Preview {
    MealParsingErrorView(message: "Could not connect to the server", onBack: { print("") })
}
