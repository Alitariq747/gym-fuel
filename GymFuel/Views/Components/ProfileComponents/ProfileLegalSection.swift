import SwiftUI

struct ProfileLegalSection: View {
    let privacyURL: URL?
    let termsURL: URL?
    let supportURL: URL?
    let onOpenNutritionSources: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "Legal")

            VStack(spacing: 0) {
                buttonRow(title: "Nutrition Sources & Methodology", systemImage: "books.vertical.fill", action: onOpenNutritionSources)
                CircaHairline(weight: .inCard)
                linkRow(title: "Privacy Policy", systemImage: "hand.raised.fill", url: privacyURL)
                CircaHairline(weight: .inCard)
                linkRow(title: "Terms of Service", systemImage: "checkmark.seal.fill", url: termsURL)
                CircaHairline(weight: .inCard)
                linkRow(title: "Contact Support", systemImage: "envelope.fill", url: supportURL)
            }
            .padding(.horizontal, 14)
            .background(ProfileCardBackground())
        }
        .padding(.horizontal, Circa.Space.screenMargin)
    }

    private func rowContent(title: String, systemImage: String) -> some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.circaRow)
                    .foregroundStyle(Color.circaInk2)
                    .frame(width: 30)

                Text(title)
                    .font(.circaRow)
                    .foregroundStyle(Color.circaInk)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.circaCaption)
                .foregroundStyle(Color.circaInk3)
                .padding(.leading, 6)
        }
        .frame(minHeight: Circa.minHitTarget)
        .contentShape(Rectangle())
    }

    private func linkRow(title: String, systemImage: String, url: URL?) -> some View {
        Group {
            if let url {
                Link(destination: url) {
                    rowContent(title: title, systemImage: systemImage)
                }
            } else {
                rowContent(title: title, systemImage: systemImage)
            }
        }
        .buttonStyle(.plain)
    }

    private func buttonRow(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            rowContent(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }
}
