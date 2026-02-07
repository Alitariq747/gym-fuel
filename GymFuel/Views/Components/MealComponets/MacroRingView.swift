//
//  MacroRingView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/12/2025.
//

import SwiftUI

import SwiftUI

struct MacroRingView: View {

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

    var body: some View {
        VStack(spacing: 8) {

//            // Top row: icon + labels
//            HStack(alignment: .firstTextBaseline, spacing: 8) {
//                Image(systemName: image)
//                    .font(.system(size: 16, weight: .semibold))
//                    .foregroundStyle(tint)
//                    .animation(.easeInOut(duration: 0.20), value: isOverTarget)
//
//                VStack(alignment: .leading, spacing: 2) {
//                    Text(title)
//                        .font(.caption)
//                        .foregroundStyle(.secondary)
//
//                    Text("\(Int(consumed)) \(unit)")
//                        .font(.subheadline.weight(.semibold))
//                }
//
//                Spacer()
//
//                if target > 0 {
//                    Text("of \(Int(target))")
//                        .font(.caption2)
//                        .foregroundStyle(.secondary)
//                }
//            }
            Text(title.capitalized)
                .foregroundStyle(.secondary)

            // Horizontal progress bar
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(tint)
                .frame(height: 6)
                .clipShape(Capsule())
                .animation(
                    .spring(response: 0.45, dampingFraction: 0.9),
                    value: progress
                )
                .animation(
                    .easeInOut(duration: 0.20),
                    value: isOverTarget
                )
            
            HStack(spacing: 0) {
                Text("\(Int(consumed))")
                    .font(.system(size: 16, weight: .semibold))
                Text(" / \(Int(target)) \(unit)")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
       
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(Int(consumed)) of \(Int(target)) \(unit)")
    }
}


#Preview {
    
    ZStack {
        AppBackground()
        MacroRingView(title: "Protein", unit: "g", target: 100, consumed: 50, image: "bolt.fill", color: .green)
    }
}
