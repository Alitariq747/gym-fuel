import SwiftUI

struct liftEatsIntro: View {
    let onNext: () -> Void

    /// One dish as a food database holds it. These are not Circa estimates, so
    /// they carry no certainty rule — Circa vouches for none of these numbers.
    private let searchResults: [(name: String, kcal: String)] = [
        ("Chicken stew", "120"),
        ("Chicken stew, homemade", "185"),
        ("CHICKEN STEW (1 serving)", "240"),
        ("chicken stew (mum's)", "320")
    ]

    var body: some View {
        VStack(spacing: 0) {
            AdaptiveScrollContainer {
                VStack(alignment: .leading, spacing: 26) {
                    CircaSectionLabel("Search results · chicken stew")

                    CircaCard(
                        inset: EdgeInsets(
                            top: 6,
                            leading: Circa.Space.cardInset,
                            bottom: 6,
                            trailing: Circa.Space.cardInset
                        )
                    ) {
                        VStack(spacing: 0) {
                            ForEach(Array(searchResults.enumerated()), id: \.offset) { index, result in
                                if index > 0 { CircaHairline(weight: .inCard) }
                                SearchResultRow(name: result.name, kcal: result.kcal)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Four numbers for one dish. None of them yours.")
                            .font(.circaTitle)
                            .foregroundStyle(Color.circaInk)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Circa has no database to search. Say what you ate in your own words — it works out the rest, then shows you every assumption it made.")
                            .font(.circaBody)
                            .foregroundStyle(Color.circaInk2)
                            .fixedSize(horizontal: false, vertical: true)
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

private struct SearchResultRow: View {
    let name: String
    let kcal: String

    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.circaBody)
                .foregroundStyle(Color.circaInk)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Text(kcal)
                .font(.circaMono)
                .monospacedDigit()
                .foregroundStyle(Color.circaInk2)
        }
        .frame(minHeight: 46)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(kcal) calories")
    }
}

#Preview {
    liftEatsIntro(onNext: {})
}
