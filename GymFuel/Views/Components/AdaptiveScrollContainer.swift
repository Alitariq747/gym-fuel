import SwiftUI

/// Keeps short content filling the available height while allowing taller content
/// (or content compressed by the keyboard) to scroll instead of being clipped.
struct AdaptiveScrollContainer<Content: View>: View {
    private let showsIndicators: Bool
    private let content: Content

    init(
        showsIndicators: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.showsIndicators = showsIndicators
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: showsIndicators) {
                content
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height, alignment: .top)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}
