import SwiftUI

/// Takes the loading screen's place when launch could not load the profile.
/// Sign out is the way out when retrying cannot help: a profile that will not
/// decode, or a read the rules refuse.
struct ProfileLoadErrorView: View {
    let message: String
    let onRetry: () -> Void
    let onSignOut: () -> Void

    var body: some View {
        // The scroll is for the largest text sizes, where a long message
        // outgrows the screen; otherwise it stays centred.
        ViewThatFits(in: .vertical) {
            content
            ScrollView { content.padding(.vertical, 24) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient.circaPaper.ignoresSafeArea())
    }

    private var content: some View {
        VStack(spacing: 18) {
            Image(decorative: "CircaMark")
                .resizable()
                .frame(width: 56, height: 56)

            Text(message)
                .font(.circaBody)
                .foregroundStyle(Color.circaInk2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 4) {
                Button(action: onRetry) {
                    Text("Try again")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary, height: 52))

                Button("Sign out", action: onSignOut)
                    .buttonStyle(.circa(.quiet))
            }
        }
        .padding(.horizontal, Circa.Space.screenMargin)
    }
}

#Preview {
    ProfileLoadErrorView(
        message: "You're offline or the connection is unstable. Please try again.",
        onRetry: {},
        onSignOut: {}
    )
}
