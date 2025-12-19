//
//  FuelScoreOverlay.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 19/12/2025.
//

import SwiftUI

struct FuelScoreOverlay: View {
    let score: FuelScore
    let onLearnMore: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.heart.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.orange.opacity(0.9))

                        Text("Today’s fuel score")
                            .font(.caption.weight(.semibold))
                    }

                    Spacer()

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(6)
                            .background(
                                Circle().fill(Color.white.opacity(0.9))
                            )
                    }
                    .buttonStyle(.plain)
                }

                // Scores row
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(score.total)")
                            .font(.subheadline.weight(.semibold))
                    }

                    Divider()
                        .frame(height: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Macros")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(score.macroAdherence)")
                            .font(.subheadline.weight(.semibold))
                    }

                    Divider()
                        .frame(height: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Timing")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(score.timingAdherence)")
                            .font(.subheadline.weight(.semibold))
                    }
                }

                Button {
                    onLearnMore()
                } label: {
                    HStack(spacing: 6) {
                        Text("How do we calculate this?")
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.orange.opacity(0.9))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)
            .padding(.top, 60)      // vertical position on screen
            .padding(.leading, 16)  // horizontal position on screen
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}


#Preview {
    FuelScoreOverlay(score: FuelScore(total: 84, macroAdherence: 65, timingAdherence: 72), onLearnMore: { print("")}, onDismiss: { print("")})
}
