import SwiftUI

/// The top of every paywall page: the plate mark, a label and a headline.
struct PaywallPageHeader<Title: View>: View {
    let label: String
    var subtitle: String?
    @ViewBuilder var title: () -> Title

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image("CircaMark")
                .resizable()
                .frame(width: 56, height: 56)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 10) {
                CircaSectionLabel(label)
                title()
                    .font(.circaTitle)
                    .foregroundStyle(Color.circaInk)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(.circaBody)
                        .foregroundStyle(Color.circaInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension PaywallPageHeader where Title == Text {
    init(label: String, title: String, subtitle: String? = nil) {
        self.init(label: label, subtitle: subtitle) { Text(title) }
    }
}
