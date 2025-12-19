//
//  FuelScoreDetailSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 19/12/2025.
//

import SwiftUI

import SwiftUI

struct FuelScoreDetailSheet: View {
    let score: FuelScore

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // 1) Big fuel score header
                        headerCard

                        // 2) Macro vs timing breakdown
                        breakdownCard

                        // 3) LiftEats thought process
                        thoughtProcessCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Fuel score details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Header: big score card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today’s fuel score")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.20), lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: CGFloat(score.total) / 100)
                        .stroke(
                            LinearGradient(
                                colors: [Color.liftEatsCoral, .orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(score.total)")
                            .font(.system(size: 26, weight: .bold))
                        Text("/ 100")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 90, height: 90)

                VStack(alignment: .leading, spacing: 6) {
                    Text("How well you fueled your training today.")
                        .font(.subheadline.weight(.semibold))

                    Text("Higher scores mean your macros and meal timing lined up with the work you asked your body to do.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 8)
    }

    // MARK: - Breakdown: macros & timing bars

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Macro & timing breakdown")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            ScoreBarRow(
                title: "Macro adherence",
                value: score.macroAdherence,
                caption: "How close you were to your calorie, protein, carb and fat targets overall."
            )

            ScoreBarRow(
                title: "Timing adherence",
                value: score.timingAdherence,
                caption: "How well you placed carbs and protein around your workout."
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 6)
    }

    // MARK: - Thought process text

    private var thoughtProcessCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LiftEats’ thought process")
                .font(.headline)

            // Overall fuel score
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.heart.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.liftEatsCoral)
                    Text("Fuel score (overall)")
                        .font(.subheadline.weight(.semibold))
                }

                Text("""
Your Fuel Score is my quick, 0–100 snapshot of how well you fueled your body today for your goal and your training.

I blend two things:
• Did you hit your macros for the day?
• Did you place carbs and protein smartly around your workout?

On lighter days I care more about totals; on hard days I care more about timing as well.
""")
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // Macro adherence
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    Text("Macro adherence")
                        .font(.subheadline.weight(.semibold))
                }

                Text("""
Here I’m asking: out of what we planned for the day, how close did you actually get?

I look at calories, protein, carbs and fats. Calories and protein matter the most, carbs and fats slightly less. You don’t need to be perfect – small misses are fine. The further you drift above or below your targets, the more this score gently drops.
""")
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // Timing adherence
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.subheadline)
                        .foregroundStyle(.purple)
                    Text("Timing adherence")
                        .font(.subheadline.weight(.semibold))
                }

                Text("""
Timing is about when you place your fuel.

On training days I look at what you ate before and after your session: some carbs + protein before to power the workout, and carbs + protein after to kick-start recovery. On easy days, timing matters less; on all-out days, it can matter almost as much as the totals.
""")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 6)
    }
}

// MARK: - Reusable score bar row

private struct ScoreBarRow: View {
    let title: String
    let value: Int
    let caption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(value)/100")
                    .font(.subheadline.weight(.semibold))
            }

            ProgressView(value: Double(value) / 100.0)
                .progressViewStyle(.linear)
                .tint(Color.liftEatsCoral)
                .frame(height: 6)
                .clipShape(Capsule())

            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    FuelScoreDetailSheet(score: FuelScore(total: 85, macroAdherence: 82, timingAdherence: 60))
}
