//
//  SessionStateCard.swift
//  GymFuel
//
//  Created for phase/substate guidance rendering.
//

import SwiftUI

struct SessionStateCard: View {
    let content: SessionStateContent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(toneColor)
                    .frame(width: 8, height: 8)

                Text(content.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()


            }

            Text(content.message)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Divider()

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Next:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(toneColor)

                Text(content.nextRecommendation)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(toneColor.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

private extension SessionStateCard {
    var toneColor: Color {
        switch content.tone {
        case .calm:
            return .blue
        case .focused:
            return .indigo
        case .assertive:
            return .orange
        case .recovery:
            return .green
        }
    }
}

#Preview {
    SessionStateCard(
        content: SessionStateContent(
            title: "Prep Window Open",
            message: "You have time to set up steady pre-workout fuel.",
            nextRecommendation: "Plan a light carb + protein meal before training.",
            tone: .focused
        )
    )
    .padding()
}
