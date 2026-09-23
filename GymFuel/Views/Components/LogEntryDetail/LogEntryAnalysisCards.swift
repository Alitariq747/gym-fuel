import SwiftUI

struct LiftEatsAnalysisCard: View {
    let explanation: String
    @State private var showNutritionSources = false

    private var cardBackground: Color {
        Color.circaCard
    }

    private var cardStroke: Color {
        Color.circaCardBorder
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
                    .foregroundStyle(Color.circaInk)
            }

            Text(explanation)
                .font(.subheadline)
                .foregroundStyle(Color.circaInk)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Button {
                showNutritionSources = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.circaAccent)
                        .frame(width: 24, height: 24)
                        .background(Color.circaWell, in: Circle())

                    Text("AI estimate · How this works & sources")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.circaInk2)

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.circaInk3)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(cardStroke, lineWidth: 1))
        .sheet(isPresented: $showNutritionSources) {
            NutritionSourcesView()
        }
    }
}

struct AIDetailsCard: View {
    let confidenceValue: Double?
    let confidenceLevel: String
    let confidenceColor: Color
    let assumptions: [String]
    @Binding var isExpanded: Bool

    private var cardBackground: Color {
        Color.circaCard
    }

    private var cardStroke: Color {
        Color.circaCardBorder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                if let confidenceValue {
                    confidenceRing(confidenceValue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Confidence level")
                            .font(.caption)
                            .foregroundStyle(Color.circaInk2)
                        Text(confidenceLevel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(confidenceColor)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Details")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.circaInk)
                        Text("Additional interpretation notes")
                            .font(.caption)
                            .foregroundStyle(Color.circaInk2)
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
                            .foregroundStyle(Color.circaInk2)
                            .frame(width: 30, height: 30)
                            .background(Color.circaWell, in: Circle())
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
                            .foregroundStyle(Color.circaAccent)

                        Text("Assumptions")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.circaInk2)
                    }

                    ForEach(assumptions, id: \.self) { assumption in
                        Text(assumption)
                            .font(.footnote)
                            .foregroundStyle(Color.circaInk2)
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
