//
//  WelcomeView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 13/12/2025.
//

import SwiftUI
import GoogleSignInSwift
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
            VStack(spacing: 16) {
            Spacer(minLength: 24)

            Image("LiftEatsWelcomeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 220, height: 220)
                .padding(.top, 16)
                

            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome to LiftEats")
                    .font(.title.bold())

                Text("Log what you eat. Track how you train. Move closer to your goal.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer()

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
                .frame(height: 48)
                .frame(maxWidth: .infinity)
                .disabled(isAppleLoading)
                // ASAuthorizationAppleIDButton fixes its style at init, so SwiftUI does
                // not restyle it when the appearance changes. Without a new identity a
                // light-mode button stays black after a switch to dark, leaving it
                // invisible against the black background.
                .id(colorScheme)

                Button {
                    Task { await handleGoogleSignIn() }
                } label: {
                    socialButtonLabel(
                        icon: googleIcon,
                        text: isGoogleLoading ? "Connecting…" : "Continue with Google",
                        isLoading: isGoogleLoading
                    )
                }
                .buttonStyle(.plain)
                .disabled(isGoogleLoading)

                if let authError {
                    Text(authError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    onSignUp()
                } label: {
                    Text("Sign up")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(height: 48)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: buttonCornerRadius)
                                .fill(socialBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: buttonCornerRadius)
                                .strokeBorder(socialBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)


                Button {
                    onSignIn()
                } label: {
                    Text("Already have an account? Sign in")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            }
        }
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

    /// Measured off the native Sign in with Apple button, whose corner radius cannot be
    /// enlarged from SwiftUI: a 6pt *circular* corner, not a continuous squircle. Every
    /// custom button on this screen matches it so the stack reads as one control group.
    private let buttonCornerRadius: CGFloat = 6

    private var socialBackground: Color {
        colorScheme == .light ? Color(.systemBackground) : Color(.secondarySystemBackground)
    }

    private var socialBorder: Color {
        colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.12)
    }

    private var googleIcon: some View {
        Image("GoogleLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
    }

    private func socialButtonLabel(icon: some View, text: String, isLoading: Bool) -> some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 18, height: 18)
            } else {
                icon
            }

            Text(text)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(height: 48)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: buttonCornerRadius)
                .fill(socialBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: buttonCornerRadius)
                .strokeBorder(socialBorder, lineWidth: 1)
        )
    }
}


#Preview {
    WelcomeView(onSignIn: {print("")}, onSignUp: { print("")})
        .environmentObject(FirebaseAuthManager())
}
