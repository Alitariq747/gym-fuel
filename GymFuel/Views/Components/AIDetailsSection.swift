//
//  AIDetailsSection.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 17/12/2025.
//

import SwiftUI

struct AIDetailsSection: View {
    let parsed: ParsedMeal

    @State private var isExpanded = false
    
    private let expandAnimation = Animation.easeInOut(duration: 0.35)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // HEADER ROW: confidence + chevron
            Button {
                withAnimation(expandAnimation) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI confidence")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(confidenceText)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundStyle(.primary)
                        .animation(expandAnimation, value: isExpanded)
                }
                .contentShape(Rectangle())  // make full row tappable
            }
            .buttonStyle(.plain)
            // DETAILS: only visible when expanded
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {

                    if let notes = parsed.notes, !notes.isEmpty {
                        Text("Notes")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(notes)
                            .font(.caption)
                    }

                    if !parsed.warnings.isEmpty {
                        Text("Warnings")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(parsed.warnings, id: \.self) { warning in
                            Text("• \(warning)")
                                .font(.caption)
                        }
                    }

                    if !parsed.assumptions.isEmpty {
                        Text("Assumptions")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(parsed.assumptions, id: \.self) { assumption in
                            Text("• \(assumption)")
                                .font(.caption)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(expandAnimation, value: isExpanded)            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.85))
        )
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
    }

    private var confidenceText: String {
        if let c = parsed.confidence {
            let percent = (c * 100).rounded()
            return "\(Int(percent))%"
        } else {
            return "Not available"
        }
    }
}


#Preview {
        AIDetailsSection(parsed: demo)
}
