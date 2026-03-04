//
//  MealParsingLoadingView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 18/12/2025.
//

import SwiftUI

struct MealParsingLoadingView: View {
    @State private var spinnerRotation: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 4)
                    .frame(width: 26, height: 26)

                Circle()
                    .trim(from: 0.05, to: 0.65)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.liftEatsCoral,
                                Color.fuelOrange,
                                Color.liftEatsCoral
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 26, height: 26)
                    .rotationEffect(.degrees(spinnerRotation))
                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: spinnerRotation)
            }

            Text("Estimating your meal…")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(.primary.opacity(0.08), lineWidth: 1)
                )
        )
        .task {
            spinnerRotation = 360
        }
    }
}



#Preview {
    MealParsingLoadingView()
}
