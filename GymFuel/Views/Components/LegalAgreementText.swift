import SwiftUI

struct LegalAgreementText: View {
    enum Context {
        case creatingAccount

        var prefix: String {
            switch self {
            case .creatingAccount:
                return "By creating an account, you agree to our"
            }
        }
    }

    let context: Context

    private let privacyURL = URL(string: "https://alitariq747.github.io/lifteats-legal/privacy-policy")!
    private let termsURL = URL(string: "https://alitariq747.github.io/lifteats-legal/terms")!

    var body: some View {
        WrappingHStack(horizontalSpacing: 4, verticalSpacing: 2) {
            Text(context.prefix)
                .foregroundStyle(.secondary)

            Link("Terms of Service", destination: termsURL)
                .foregroundStyle(.primary)
                .underline()

            Text("and acknowledge our")
                .foregroundStyle(.secondary)

            Link("Privacy Policy", destination: privacyURL)
                .foregroundStyle(.primary)
                .underline()

            Text(".")
                .foregroundStyle(.secondary)
        }
        .font(.caption2)
        .tint(.primary)
        .frame(maxWidth: .infinity)
        .opacity(0.74)
        .accessibilityElement(children: .contain)
    }
}

private struct WrappingHStack: Layout {
    var horizontalSpacing: CGFloat
    var verticalSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        layout(in: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = layout(in: bounds.width, subviews: subviews)
        let xOffset = max((bounds.width - result.size.width) / 2, 0)

        for item in result.items {
            subviews[item.index].place(
                at: CGPoint(x: bounds.minX + xOffset + item.origin.x, y: bounds.minY + item.origin.y),
                proposal: ProposedViewSize(item.size)
            )
        }
    }

    private func layout(in maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, items: [LayoutItem]) {
        var items: [LayoutItem] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let shouldWrap = x > 0 && x + size.width > maxWidth

            if shouldWrap {
                usedWidth = max(usedWidth, x - horizontalSpacing)
                x = 0
                y += lineHeight + verticalSpacing
                lineHeight = 0
            }

            items.append(LayoutItem(index: index, origin: CGPoint(x: x, y: y), size: size))
            x += size.width + horizontalSpacing
            lineHeight = max(lineHeight, size.height)
        }

        usedWidth = max(usedWidth, max(x - horizontalSpacing, 0))
        return (CGSize(width: usedWidth, height: y + lineHeight), items)
    }

    private struct LayoutItem {
        let index: Int
        let origin: CGPoint
        let size: CGSize
    }
}
