//
//  MacroRingView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/12/2025.
//

import SwiftUI

struct MacroRingView: View {

    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let unit: String
    let target: Double
    let consumed: Double
    let image: String
    let color: Color

    private var progress: Double {
        guard target > 0, target.isFinite, consumed.isFinite else { return 0 }
        let ratio = consumed / target
        guard ratio.isFinite else { return 0 }
        // 0...1 progress, clamp so the bar is full when over target
        return min(max(ratio, 0), 1)
    }

    private var isOverTarget: Bool {
        target > 0 && consumed > target
    }

    private var tint: Color {
        isOverTarget ? .red : color
    }

    private var macroSymbol: String {
        let key = title.lowercased()
        if key.contains("protein") { return "fish.fill" }
        if key.contains("carb") { return "bolt.fill" }
        if key.contains("fat") { return "drop.fill" }
        if key.contains("cal") { return "flame.fill" }
        return image
    }

    private var targetLineText: String {
        guard target > 0 else { return "/ --" }
        return "/ \(Int(target)) \(unit)"
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(title.capitalized)
                .font(.caption2)
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(colorScheme == .dark ? Color(.secondarySystemBackground) : tint.opacity(0.1), lineWidth: 7)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        tint,
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.9),
                        value: progress
                    )
                    .animation(
                        .easeInOut(duration: 0.20),
                        value: isOverTarget
                    )

                Image(systemName: macroSymbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 58, height: 58)

            VStack(spacing: 1) {
                Text("\(Int(consumed))")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                Text(targetLineText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(Int(consumed)) of \(Int(target)) \(unit)")
    }
}


#Preview {
    MacroRingView(title: "Calries", unit: "kcals", target: 100, consumed: 50, image: "bolt.fill", color: .liftEatsCoral)
}
