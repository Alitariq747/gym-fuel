import SwiftUI

struct liftEatsIntro: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            AdaptiveScrollContainer {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        CircaSectionLabel("A food journal")
                        Text("Calories don't tell the full story.")
                            .font(.circaTitle)
                            .foregroundStyle(Color.circaInk)
                        Text("Describe what you ate. See the portions and ingredients we assumed, then correct what differs from your meal.")
                            .font(.circaBody)
                            .foregroundStyle(Color.circaInk2)
                    }

                    CircaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top, spacing: 14) {
                                Image("chicken_bowl")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: Circa.Radius.thumb))
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Chicken rice bowl")
                                        .font(.circaEntryTitle)
                                    CircaEstimate("620 kcal", certainty: .estimated)
                                    Text("Example estimate")
                                        .font(.circaMono)
                                        .foregroundStyle(Color.circaInk3)
                                }
                            }
                            CircaHairline(weight: .inCard)
                            VStack(alignment: .leading, spacing: 6) {
                                CircaSectionLabel("What we assumed")
                                Text("One bowl of rice, chicken, vegetables and cooking oil. Adjust the amounts to match your bowl.")
                                    .font(.circaBody)
                                    .foregroundStyle(Color.circaInk2)
                            }
                        }
                    }
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.top, 18)
                .padding(.bottom, 20)
            }

            Button(action: onNext) {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(.circa(.primary, height: 52))
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.bottom, 16)
        }
        .circaPaper()
    }
}

#Preview {
    liftEatsIntro(onNext: {})
}
