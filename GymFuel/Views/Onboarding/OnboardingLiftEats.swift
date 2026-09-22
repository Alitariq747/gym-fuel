import SwiftUI

struct OnboardingLiftEats: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            AdaptiveScrollContainer {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        CircaSectionLabel("See the reasoning")
                        Text("Make it your meal.")
                            .font(.circaTitle)
                            .foregroundStyle(Color.circaInk)
                        Text("Circa shows what it estimated and the portions and ingredients behind the numbers.")
                            .font(.circaBody)
                            .foregroundStyle(Color.circaInk2)
                    }

                    CircaCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 12) {
                                Image("eggs_toast_coffee")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: Circa.Radius.thumb))
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("One egg, toast and coffee")
                                        .font(.circaEntryTitle)
                                    CircaEstimate("200 kcal", certainty: .estimated)
                                    Text("Example estimate")
                                        .font(.circaMono)
                                        .foregroundStyle(Color.circaInk3)
                                }
                            }
                            CircaHairline(weight: .inCard)
                            CircaSectionLabel("Circa's assumptions")
                            Text("One egg, two slices of toast and a cup of coffee. Check the amounts and change anything that differs from your breakfast.")
                                .font(.circaBody)
                                .foregroundStyle(Color.circaInk2)
                        }
                    }

                    CircaCard(.sunken) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(Color.circaAccent)
                                .accessibilityHidden(true)
                            Text("Change two slices of toast to one, and the meal total updates with it.")
                                .font(.circaBody)
                                .foregroundStyle(Color.circaInk2)
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
    OnboardingLiftEats(onNext: {})
}
