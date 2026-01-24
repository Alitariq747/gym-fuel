//
//  MealParsingLoadingView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 18/12/2025.
//

import SwiftUI

import SwiftUI

struct MealParsingLoadingView: View {
    @State private var progress: Double = 0.0
    @State private var phase: Int = 0

   
    private let phases = [
        "Analyzing your description…",
        "Estimating macros and calories…",
        "Checking ingredients and portions…",
        "Almost done, polishing your meal…"
    ]

    var body: some View {
        VStack(spacing: 20) {
          
            VStack(spacing: 8) {
                Image(systemName: "wand.and.stars.inverse")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.liftEatsCoral)

                Text("Estimating your meal")
                    .font(.title3.weight(.semibold))

                Text(phases[min(phase, phases.count - 1)])
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            
            VStack(spacing: 6) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(Color.liftEatsCoral)

                Text("\(Int(progress * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text("This usually takes a few seconds.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.85))
        )
        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 10)
        .padding(.horizontal, 24)
        .task {
            await animateProgress()
        }
    }

    @MainActor
    private func animateProgress() async {
       
        while progress < 0.95 {
            
            try? await Task.sleep(nanoseconds: 250_000_000)

          
            let step: Double = 0.03
            progress = min(progress + step, 0.95)

          
            switch progress {
            case 0.0..<0.25:
                phase = 0
            case 0.25..<0.5:
                phase = 1
            case 0.5..<0.8:
                phase = 2
            default:
                phase = 3
            }
        }
    }
}



#Preview {
    MealParsingLoadingView()
}
