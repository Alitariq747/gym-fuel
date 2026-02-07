//
//  DayLoadingOverlayView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 07/02/2026.
//

import SwiftUI

struct DayLoadingOverlayView: View {
    @State private var progress: Double = 0.08
    @State private var phaseIndex: Int = 0
    @State private var isPulsing: Bool = false

    private let phases = [
        "Warming up your plan…",
        "Calculating your macros…",
        "Syncing meals and activity…",
        "Almost ready for today…"
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("LiftEatsWelcomeIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .scaleEffect(isPulsing ? 1.02 : 0.98)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isPulsing)

                VStack(spacing: 6) {
                    Text("Loading your day")
                        .font(.title3.weight(.semibold))

                    Text(phases[min(phaseIndex, phases.count - 1)])
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(Color.liftEatsCoral)

                    Text("\(Int(progress * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Text("This usually takes just a moment.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)
            .padding(.horizontal, 24)
        }
        .onAppear {
            isPulsing = true
        }
        .task {
            await animateProgress()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading your day")
    }

    @MainActor
    private func animateProgress() async {
        while progress < 0.92 {
            try? await Task.sleep(nanoseconds: 220_000_000)

            let step = Double.random(in: 0.02...0.05)
            let next = min(progress + step, 0.92)
            withAnimation(.easeInOut(duration: 0.25)) {
                progress = next
            }

            switch progress {
            case 0.0..<0.32:
                phaseIndex = 0
            case 0.32..<0.6:
                phaseIndex = 1
            case 0.6..<0.84:
                phaseIndex = 2
            default:
                phaseIndex = 3
            }
        }
    }
}

#Preview {
    DayLoadingOverlayView()
}
