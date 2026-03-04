//
//  ScanBeamOverlay.swift
//  GymFuel
//
//  Created by Codex on 03/03/2026.
//

import SwiftUI

struct ScanBeamOverlay: View {
    @State private var beamOffset: CGFloat = -1

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.45),
                            Color.white.opacity(0.18),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width * 0.25)
                .offset(x: beamOffset * width)
                .onAppear {
                    beamOffset = -0.2
                    withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                        beamOffset = 1.2
                    }
                }
        }
        .allowsHitTesting(false)
        .clipped()
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.08)
        ScanBeamOverlay()
    }
    .frame(width: 280, height: 180)
}
