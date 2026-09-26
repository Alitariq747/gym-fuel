import SwiftUI

struct OnboardingMetricPage<Content: View>: View {
    let title: String
    /// Optional: a step whose question answers itself carries no subtitle.
    let detail: String?
    let onContinue: () -> Void
    let content: Content

    init(title: String, detail: String? = nil, onContinue: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.detail = detail
        self.onContinue = onContinue
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            AdaptiveScrollContainer {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 10) {
                        CircaSectionLabel("About you")

                        Text(title)
                            .font(.circaTitle)
                            .foregroundStyle(Color.circaInk)
                            .fixedSize(horizontal: false, vertical: true)

                        if let detail {
                            Text(detail)
                                .font(.circaBody)
                                .foregroundStyle(Color.circaInk2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    content
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }

            Button(action: onContinue) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.circa(.primary, height: 52))
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .circaPaper()
    }
}
