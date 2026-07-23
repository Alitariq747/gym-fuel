import SwiftUI

struct ProfileLiftEatsSection: View {
    let onOpenScoreExplanation: () -> Void
    let reviewURL: URL

    var body: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "LiftEats", systemImage: "sparkles")

            VStack(spacing: 0) {
                Button(action: onOpenScoreExplanation) {
                    actionRow(
                        title: "How score is calculated",
                        systemImage: "chart.line.uptrend.xyaxis",
                        tint: .fuelOrange
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.leading, 82)

                Link(destination: reviewURL) {
                    actionRow(
                        title: "Rate LiftEats",
                        systemImage: "star.fill",
                        tint: .fuelOrange
                    )
                }
                .buttonStyle(.plain)
            }
            .background(ProfileCardBackground())
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.fuelOrange.opacity(0.12), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }

    private func actionRow(title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.12))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: systemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(tint)
                )

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.leading, 4)
        }
        .contentShape(Rectangle())
        .padding(16)
    }
}
