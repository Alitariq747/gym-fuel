import SwiftUI

struct AnalysisLoadingStatusLine: View {
    let text: String
    var symbolName: String = "sparkles"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBreathing = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbolName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.fuelBlue.opacity(0.78))
                .opacity(reduceMotion ? 0.82 : (isBreathing ? 0.42 : 0.86))
                .accessibilityHidden(true)

            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .id(text)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: text)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
        .onChange(of: reduceMotion) { _, isEnabled in
            if isEnabled {
                isBreathing = false
            }
        }
    }
}

struct AnalysisProgressRail: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSweeping = false

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let sweepWidth = max(width * 0.34, 44)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.tertiarySystemFill))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.fuelBlue.opacity(0.10),
                                Color.fuelBlue.opacity(0.42),
                                Color.fuelGreen.opacity(0.28)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: reduceMotion ? width * 0.42 : sweepWidth)
                    .offset(x: reduceMotion ? 0 : (isSweeping ? width : -sweepWidth))
            }
            .clipShape(Capsule())
        }
        .frame(height: 3)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            isSweeping = false
            withAnimation(.easeInOut(duration: 1.45).repeatForever(autoreverses: false)) {
                isSweeping = true
            }
        }
        .onChange(of: reduceMotion) { _, isEnabled in
            if isEnabled {
                isSweeping = false
            }
        }
    }
}
