import SwiftUI
import AuthenticationServices

struct AuthChoicesView: View {
    enum Mode: Equatable {
        case signIn
        case saveProgress
    }

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var authManager: FirebaseAuthManager
    let mode: Mode
    let onBack: () -> Void
    let onEmail: () -> Void
    let onAuthenticated: (AuthAccountOutcome) -> Void

    @State private var isGoogleLoading = false
    @State private var isAppleLoading = false
    @State private var authError: String?
    @State private var appleNonce: String?

    private var isBusy: Bool { isGoogleLoading || isAppleLoading }

    var body: some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 0) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.circaInk)
                        .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                        .background(Color.circaCard, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                .disabled(isBusy)

                Spacer(minLength: 36)

                if mode == .saveProgress {
                    ZStack {
                        Circle()
                            .fill(Color.circaWell)
                            .frame(width: 168, height: 168)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 76, weight: .light))
                            .foregroundStyle(Color.circaAccent)
                            .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 42)
                }

                VStack(alignment: .leading, spacing: 12) {
                    CircaSectionLabel(mode == .saveProgress ? "Your journal" : "Your account")
                    Text(mode == .saveProgress ? "Save your progress" : "Welcome back")
                        .font(.circaTitle)
                        .foregroundStyle(Color.circaInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(mode == .saveProgress
                         ? "Create an account to keep your plan and food journal in sync across devices."
                         : "Choose how you'd like to continue with your food journal.")
                        .font(.circaBody)
                        .foregroundStyle(Color.circaInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 32)

                VStack(spacing: 14) {
                    SignInWithAppleButton(.continue) { request in
                        let nonce = authManager.generateNonce()
                        appleNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = authManager.sha256(nonce)
                    } onCompletion: { result in
                        Task { await handleAppleSignIn(result) }
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 52)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: Circa.Radius.button))
                    .disabled(isBusy)
                    .id(colorScheme)

                    Button {
                        Task { await handleGoogleSignIn() }
                    } label: {
                        HStack(spacing: 10) {
                            if isGoogleLoading {
                                ProgressView().controlSize(.small)
                            } else {
                                Image("GoogleLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                            }
                            Text(isGoogleLoading ? "Connecting…" : "Continue with Google")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.circa(.secondary, height: 52))
                    .disabled(isBusy)

                    HStack(spacing: 12) {
                        Rectangle().fill(Color.circaCardBorder).frame(height: 1)
                        Text("or")
                            .font(.circaCaption)
                            .foregroundStyle(Color.circaInk3)
                        Rectangle().fill(Color.circaCardBorder).frame(height: 1)
                    }
                    .padding(.vertical, 4)

                    Button(action: onEmail) {
                        Text(mode == .saveProgress ? "Use email instead" : "Continue with email")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.circa(.primary, height: 52))
                    .disabled(isBusy)

                    if let authError {
                        Text(authError)
                            .font(.circaCaption)
                            .foregroundStyle(Color.circaDanger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if mode == .saveProgress {
                        LegalAgreementText(context: .creatingAccount)
                    }
                }
            }
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .circaPaper()
        .navigationBarBackButtonHidden(true)
    }

    @MainActor
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        guard !isBusy else { return }
        authError = nil
        isAppleLoading = true
        defer { isAppleLoading = false }

        do {
            let authorization = try result.get()
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8),
                  let appleNonce else {
                throw AuthManagerError.unknown
            }
            let outcome = try await authManager.signInWithApple(
                idTokenString: token,
                rawNonce: appleNonce,
                fullName: credential.fullName
            )
            onAuthenticated(outcome)
        } catch {
            if let error = error as? AuthManagerError, error == .operationCancelled { return }
            let nsError = error as NSError
            if nsError.domain == ASAuthorizationError.errorDomain,
               ASAuthorizationError.Code(rawValue: nsError.code) == .canceled { return }
            authError = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't sign you in with Apple. Please try again."
            )
        }
    }

    @MainActor
    private func handleGoogleSignIn() async {
        guard !isBusy else { return }
        authError = nil
        isGoogleLoading = true
        defer { isGoogleLoading = false }

        do {
            let outcome = try await authManager.signInWithGoogle()
            onAuthenticated(outcome)
        } catch {
            if let error = error as? AuthManagerError, error == .operationCancelled { return }
            authError = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't sign you in with Google. Please try again."
            )
        }
    }
}
