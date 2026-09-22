//
//  WelcomeView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 13/12/2025.
//

import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var authManager: FirebaseAuthManager
    let onSignIn: () -> Void
    let onSignUp: () -> Void
    
    @State private var isGoogleLoading = false
    @State private var isAppleLoading = false
    @State private var authError: String?
    @State private var appleNonce: String?

    var body: some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Circa")
                        .font(.system(.title2).weight(.semibold))
                        .foregroundStyle(Color.circaInk)

                    CircaSectionLabel("Food & calorie journal")
                }

                Spacer(minLength: 48)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Your food, in your words.")
                        .font(.system(.largeTitle).weight(.semibold))
                        .foregroundStyle(Color.circaInk)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Describe a meal or add a photo. See the portions and ingredients we assumed, then correct what differs.")
                        .font(.circaBody)
                        .foregroundStyle(Color.circaInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 48)

                VStack(spacing: 12) {
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
                    .disabled(isAppleLoading)
                    // The native button fixes its appearance at creation time.
                    .id(colorScheme)

                    Button {
                        Task { await handleGoogleSignIn() }
                    } label: {
                        HStack(spacing: 10) {
                            if isGoogleLoading {
                                ProgressView()
                                    .controlSize(.small)
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
                    .disabled(isGoogleLoading)

                    if let authError {
                        Text(authError)
                            .font(.circaCaption)
                            .foregroundStyle(Color.circaDanger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button(action: onSignUp) {
                        Text("Sign up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.circa(.outline, height: 52))

                    Button(action: onSignIn) {
                        Text("Already have an account? Sign in")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.circa(.link))
                }
            }
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.top, 32)
            .padding(.bottom, 24)
        }
        .circaPaper()
    }

    @MainActor
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        guard !isAppleLoading else { return }
        authError = nil
        isAppleLoading = true
        defer { isAppleLoading = false }

        do {
            let authResult = try result.get()
            guard let credential = authResult.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthManagerError.unknown
            }
            guard let tokenData = credential.identityToken,
                  let tokenString = String(data: tokenData, encoding: .utf8) else {
                throw AuthManagerError.unknown
            }
            guard let rawNonce = appleNonce else {
                throw AuthManagerError.unknown
            }
            try await authManager.signInWithApple(
                idTokenString: tokenString,
                rawNonce: rawNonce,
                fullName: credential.fullName
            )
        } catch {
            if let authError = error as? AuthManagerError {
                if authError == .operationCancelled { return }
                self.authError = authError.localizedDescription
                return
            }

            let nsError = error as NSError
            if nsError.domain == ASAuthorizationError.errorDomain,
               let code = ASAuthorizationError.Code(rawValue: nsError.code),
               code == .canceled {
                return
            }

            authError = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't sign you in with Apple. Please try again."
            )
        }
    }

    @MainActor
    private func handleGoogleSignIn() async {
        guard !isGoogleLoading else { return }
        authError = nil
        isGoogleLoading = true
        defer { isGoogleLoading = false }

        do {
            try await authManager.signInWithGoogle()
        } catch {
            if let authError = error as? AuthManagerError {
                if authError == .operationCancelled { return }
                self.authError = authError.localizedDescription
            } else {
                authError = AppErrorMessage.message(
                    for: error,
                    fallback: "We couldn't sign you in with Google. Please try again."
                )
            }
        }
    }

}


#Preview {
    WelcomeView(onSignIn: {print("")}, onSignUp: { print("")})
        .environmentObject(FirebaseAuthManager())
}
