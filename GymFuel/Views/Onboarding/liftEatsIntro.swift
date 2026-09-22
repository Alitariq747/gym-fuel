//
//  liftEatsIntro.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 18/05/2026.
//

import SwiftUI

struct liftEatsIntro: View {
    let onNext: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    var body: some View {
        AdaptiveScrollContainer {
            VStack {
           
            VStack(alignment: .leading, spacing: 10) {
                Text("Calories don’t tell the full story.")
                    .font(.title2.bold())
                    .lineSpacing(0)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Describe what you ate. See the portions and ingredients we assumed, then correct what differs from your meal.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: reduceMotion || hasAppeared ? 0 : 10)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.55), value: hasAppeared)

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image("chicken_bowl")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Chicken Rice Bowl")
                            .font(.headline.weight(.semibold))

                        HStack(spacing: 18) {
                            macroValue("620", label: "CAL")
                            macroValue("44g", label: "PRO")
                            macroValue("52g", label: "CARB")
                            macroValue("20g", label: "FAT")
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("What we assumed")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("One bowl of rice, chicken, vegetables and cooking oil. Adjust the amounts to match your bowl.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color(.quaternaryLabel), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
            .opacity(hasAppeared ? 1 : 0)
            .scaleEffect(reduceMotion || hasAppeared ? 1 : 0.97)
            .offset(y: reduceMotion || hasAppeared ? 0 : 16)
            .animation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.86).delay(0.18), value: hasAppeared)

            Spacer()
            Button {
                onNext()
            } label: {
                Text("Continue")
                    .font(.headline.bold())
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.black, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
            .padding()
        }
        .onAppear {
            hasAppeared = true
        }
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }

    private func macroValue(_ value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    liftEatsIntro(onNext: {})
}
