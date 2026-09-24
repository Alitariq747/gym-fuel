import SwiftUI

private enum PostOnboardingAuthRoute: Hashable {
    case signUpEmail
}

struct PostOnboardingAuthView: View {
    @EnvironmentObject private var authManager: FirebaseAuthManager
    let isFinishing: Bool
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
                        onAuthenticated: onAuthenticated
                    )
                } else {
                    AppLoadingView()
                        .overlay(alignment: .bottom) {
                            if let errorMessage, !isFinishing {
                                VStack(spacing: 16) {
                                    Text(errorMessage)
                                        .font(.circaBody)
                                        .foregroundStyle(Color.circaDanger)
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Button("Try again", action: onRetry)
                                        .buttonStyle(.circa(.primary, height: 52))
                                }
                                .padding(Circa.Space.screenMargin)
                                .frame(maxWidth: .infinity)
                                .background(Color.circaCard, in: RoundedRectangle(cornerRadius: Circa.Radius.card))
                                .padding(Circa.Space.screenMargin)
                            }
                        }
                }
            }
            .navigationDestination(for: PostOnboardingAuthRoute.self) { route in
                switch route {
                case .signUpEmail:
                    SignUpView(onAuthenticated: onAuthenticated)
                }
            }
        }
        .onChange(of: authManager.user?.uid) { _, uid in
            if uid != nil { path.removeAll() }
        }
    }
}
