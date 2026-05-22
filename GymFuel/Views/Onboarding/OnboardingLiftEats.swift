//
//  OnboardingLiftEats.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 18/05/2026.
//

import SwiftUI

struct OnboardingLiftEats: View {
    let onNext: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cardsAppeared = false

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Small changes; Better results.")
                }
                .font(.title2.bold())

                Text("After every log, LiftEats explains what worked, what could improve, and how to make your next meal better for your goal.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image("eggs_toast_coffee")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("1 Egg 2 Toast & Coffee")
                            .font(.headline.weight(.semibold))

                        HStack(spacing: 18) {
                            macroValue("200", label: "CAL")
                            macroValue("10g", label: "PRO")
                            macroValue("15g", label: "CARB")
                            macroValue("8g", label: "FAT")
                        }
                    }
                }

                Divider()
                scoreSummary
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color(.quaternaryLabel), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
            .cardEntrance(isVisible: cardsAppeared, delay: 0.12, reduceMotion: reduceMotion)

            analysisCard
                .cardEntrance(isVisible: cardsAppeared, delay: 0.32, reduceMotion: reduceMotion)
            adjustmentCard
                .cardEntrance(isVisible: cardsAppeared, delay: 0.52, reduceMotion: reduceMotion)

            Spacer()

            Button {
                onNext()
            } label: {
                Text("Continue")
                    .font(.headline.bold())
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .onAppear {
            cardsAppeared = false
            DispatchQueue.main.async {
                cardsAppeared = true
            }
        }
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }

    private var analysisCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image("LiftEatsWelcomeIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

                Text("LiftEats analysis")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text("A simple breakfast, but for lean bulk it needs more fuel. The egg helps, while the toast and coffee leave the meal light on protein and total calories.")
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 10) {
                Text("💡")
                    .frame(width: 30, height: 30)
                    .background(Color.fuelOrange.opacity(0.14), in: Circle())
                Text("Add Greek yogurt or another egg, plus banana or oats, to turn this into a stronger muscle-building breakfast.")
                    .font(.caption.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color.fuelOrange.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(.quaternaryLabel), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private var adjustmentCard: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.fuelGreen)
                .frame(width: 40, height: 40)
                .background(Color.fuelGreen.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text("58")
                        .foregroundStyle(Color.liftEatsCoral)
                    Image(systemName: "arrow.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text("82")
                        .foregroundStyle(Color.fuelGreen)
                }
                .font(.headline.weight(.bold))

                Text("One extra egg, Greek yogurt, and oats can move this from light to goal-ready.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.quaternaryLabel), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
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

    private var scoreSummary: some View {
        HStack(spacing: 10) {
            VStack(spacing: -1) {
                Text("58")
                    .font(.subheadline.weight(.bold))
                Text("LOW")
                    .font(.system(size: 7, weight: .semibold))
            }
            .foregroundStyle(Color.liftEatsCoral)
            .frame(width: 40, height: 40)
            .background(Color.liftEatsCoral.opacity(0.14), in: Circle())

            Rectangle()
                .fill(Color.liftEatsCoral.opacity(0.14))
                .frame(width: 1, height: 32)

            Text("Good start with eggs and toast but this meal is a bit low in protein and carbs for your lean bulk goal.")
                .font(.caption2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}

private extension View {
    func cardEntrance(isVisible: Bool, delay: Double, reduceMotion: Bool) -> some View {
        opacity(isVisible ? 1 : 0)
            .offset(y: reduceMotion || isVisible ? 0 : 18)
            .animation(reduceMotion ? nil : .spring(response: 0.85, dampingFraction: 0.88).delay(delay), value: isVisible)
    }
}

#Preview {
    OnboardingLiftEats(onNext: {})
}
