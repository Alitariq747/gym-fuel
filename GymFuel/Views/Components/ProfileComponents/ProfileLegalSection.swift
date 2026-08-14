import SwiftUI

struct ProfileLegalSection: View {
    let privacyURL: URL?
    let termsURL: URL?
    let supportURL: URL?
    let onOpenNutritionSources: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "Legal", systemImage: "doc.text")

            VStack(spacing: 10) {
                buttonRow(title: "Nutrition Sources & Methodology", systemImage: "books.vertical.fill", action: onOpenNutritionSources)
                Divider()
                linkRow(title: "Privacy Policy", systemImage: "hand.raised.fill", url: privacyURL)
                Divider()
                linkRow(title: "Terms of Service", systemImage: "checkmark.seal.fill", url: termsURL)
                Divider()
                linkRow(title: "Contact Support", systemImage: "envelope.fill", url: supportURL)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemBackground).opacity(colorScheme == .dark ? 0.75 : 0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
            )
        }
        .padding(.horizontal)
        .opacity(0.92)
    }

    private func rowContent(title: String, systemImage: String) -> some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.fuelBlue)
                    .frame(width: 18)

                Text(title)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.leading, 6)
        }
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
