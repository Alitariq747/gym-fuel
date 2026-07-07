import SwiftUI

struct LiftEatsAnalysisCard: View {
    let explanation: String
    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }

    private var cardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(.quaternaryLabel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 9) {
                Image("LiftEatsWelcomeIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                Text("LiftEats Analysis")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
            }

            Text(explanation)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(cardStroke, lineWidth: 1))
    }
}

struct AIDetailsCard: View {
    let confidenceValue: Double?
    let confidenceLevel: String
    let confidenceColor: Color
    let assumptions: [String]
    @Binding var isExpanded: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }

    private var cardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(.quaternaryLabel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                if let confidenceValue {
                    confidenceRing(confidenceValue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Confidence level")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(confidenceLevel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(confidenceColor)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Details")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("Additional interpretation notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if !assumptions.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 30)
                            .background(Color(.secondarySystemBackground), in: Circle())
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .buttonStyle(.plain)
                }
            }

            if isExpanded && !assumptions.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()

                    HStack(spacing: 6) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.fuelBlue)

                        Text("Assumptions")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    ForEach(assumptions, id: \.self) { assumption in
                        Text(assumption)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(cardStroke, lineWidth: 1))
    }

    private func confidenceRing(_ value: Double) -> some View {
        ZStack {
            Circle()
                .stroke(confidenceColor.opacity(0.18), lineWidth: 5)

            Circle()
                .trim(from: 0, to: value)
                .stroke(
                    confidenceColor,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(Int((value * 100).rounded()))")
                .font(.caption.weight(.bold))
                .foregroundStyle(confidenceColor)
        }
        .frame(width: 46, height: 46)
    }
}
