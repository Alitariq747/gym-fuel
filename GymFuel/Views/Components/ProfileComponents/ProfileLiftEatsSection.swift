import SwiftUI

struct ProfileLiftEatsSection: View {
    let onOpenScoreExplanation: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "LiftEats", systemImage: "sparkles")

            Button(action: onOpenScoreExplanation) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.fuelOrange.opacity(0.12))
                            .frame(width: 52, height: 52)

                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.fuelOrange)
                    }

                    Text("How score is calculated")
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
            .buttonStyle(.plain)
            .background(ProfileCardBackground())
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.fuelOrange.opacity(0.12), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }
}
