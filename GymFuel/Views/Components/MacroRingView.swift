//
//  MacroRingView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/12/2025.
//

import SwiftUI

struct MacroRingView: View {
    
    let title: String
    let unit: String
    let target: Double
    let consumed: Double
    let image: String
    let color: Color
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(max(consumed / target , 0), 1)
    }
    private var isOverTarget: Bool {
        target > 0 && consumed > target
    }

    private var tint: Color {
        isOverTarget ? .red : color
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color(.secondarySystemBackground), lineWidth: 7)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(tint, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.45, dampingFraction: 0.9), value: progress)
                    .animation(.easeInOut(duration: 0.20), value: isOverTarget)
                
                Image(systemName: image)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(tint)
                    .animation(.easeInOut(duration: 0.20), value: isOverTarget)
               
            }
            .frame(width: 55, height: 55)
            
            VStack(spacing: 0) {
                HStack(spacing:0) {
                    Text("\(Int(consumed)) ")
                        .font(.system(size: 14, weight: .semibold))
                    Text("/\(Int(target))\(unit)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text("\(title)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
          

            }
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
