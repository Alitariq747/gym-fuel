import SwiftUI

private enum PostOnboardingAuthRoute: Hashable {
    case signUpEmail
    case signInChoices
    case signInEmail
}

struct PostOnboardingAuthView: View {
    @EnvironmentObject private var authManager: FirebaseAuthManager
    let isFinishing: Bool
    let accountIsNew: Bool?
    let errorMessage: String?
    let onBack: () -> Void
    let onRetry: () -> Void
    let onAuthenticated: (AuthAccountOutcome) -> Void

    @State private var path: [PostOnboardingAuthRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if authManager.user == nil {
                    AuthChoicesView(
                        mode: .saveProgress,
                        onBack: onBack,
                        onEmail: { path.append(.signUpEmail) },
                        onSignIn: { path.append(.signInChoices) },
                        onAuthenticated: onAuthenticated
                    )
                } else {
                    completionView
                }
            }
            .navigationDestination(for: PostOnboardingAuthRoute.self) { route in
                switch route {
                case .signUpEmail:
                    SignUpView(onAuthenticated: onAuthenticated)
                case .signInChoices:
                    AuthChoicesView(
                        mode: .signIn,
                        onBack: { _ = path.popLast() },
                        onEmail: { path.append(.signInEmail) },
                        onSignIn: nil,
                        onAuthenticated: onAuthenticated
                    )
                case .signInEmail:
                    SignInView(onAuthenticated: onAuthenticated)
                }
            }
        }
        .onChange(of: authManager.user?.uid) { _, uid in
            if uid != nil { path.removeAll() }
        }
    }

    private var completionView: some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 18) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.circaInk)
                        .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                        .background(Color.circaCard, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to your plan")
                .disabled(isFinishing)

                Spacer(minLength: 48)

                CircaSectionLabel("Your journal")
                Text(accountIsNew == false ? "Open your account" : "Finish saving your plan")
                    .font(.circaTitle)
                    .foregroundStyle(Color.circaInk)
                Text(accountIsNew == false
                     ? "You're signed in. We still need to load your journal."
                     : "You're signed in. Your plan still needs to be saved to your account.")
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaDanger)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 32)

                Button(action: onRetry) {
                    if isFinishing {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text(accountIsNew == false ? "Try opening again" : "Try saving again")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.circa(.primary, height: 52))
                .disabled(isFinishing || errorMessage == nil)
            }
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .circaPaper()
    }
}
