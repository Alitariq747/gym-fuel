//
//  OnboardingSummaryStepView.swift
//  GymFuel
//
//  Created by Codex on 04/03/2026.
//

import SwiftUI

struct OnboardingSummaryStepView: View {
    let name: String
    let trainingGoal: TrainingGoal
    let trainingDaysPerWeek: Int
    let trainingExperience: TrainingExperience
    let trainingStyle: TrainingStyle
    let trainingTimeOfDay: TrainingTimeOfDay
    let activityLevel: NonTrainingActivityLevel
    let onStart: () -> Void
    
    
    @State private var showHeader = false
    @State private var showCard1 = false
    @State private var showCard2 = false
    @State private var showCard3 = false
    @State private var showCTA = false

    var body: some View {
        VStack(spacing: 10) {
            if showHeader {
                VStack(spacing: 4) {
                    Text("Your LiftEats plan is ready")
                        .font(.title2.weight(.semibold))
                    Text("Based on your training, schedule, and goal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .transition(.move(edge: .top).combined(with: .opacity))

                Image("summary")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            VStack(spacing: 12) {
                if showCard1 {
                    summaryCard(
                        title: "Training plan",
                        value: "\(trainingDaysPerWeek)x/week · \(trainingStyle.displayName)",
                        detail: "\(trainingExperience.displayName) · \(trainingTimeOfDay.displayName)",
                        systemImage: "dumbbell.fill",
                        accentColor: Color.fuelOrange
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if showCard2 {
                    summaryCard(
                        title: "Primary goal",
                        value: trainingGoal.displayName,
                        detail: activityLevel.displayName,
                        systemImage: "target",
                        accentColor: Color.fuelGreen
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if showCard3 {
                    summaryCard(
                        title: "Fueling focus",
                        value: "Macro accuracy + timing",
                        detail: "Adjusted for when and how hard you train",
                        systemImage: "bolt.heart.fill",
                        accentColor: Color.fuelRed
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            if showCTA {
                Button(action: onStart) {
                    Text("Start LiftEats")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.primary, in: Capsule())
                        .foregroundStyle(Color(.systemBackground))
                }
                .padding(.top, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))

                Text("You can edit these anytime in Profile.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                showHeader = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showCard1 = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showCard2 = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showCard3 = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showCTA = true
                }
            }
        }
    }

    private func summaryCard(
        title: String,
        value: String,
        detail: String,
        systemImage: String,
        accentColor: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(accentColor)
                .frame(width: 28, height: 28)
                .background(accentColor.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

#Preview {
    OnboardingSummaryStepView(
        name: "Ahmad",
        trainingGoal: .muscleGain,
        trainingDaysPerWeek: 4,
        trainingExperience: .intermediate,
        trainingStyle: .strength,
        trainingTimeOfDay: .evening,
        activityLevel: .somewhatActive,
        onStart: {}
    )
}
