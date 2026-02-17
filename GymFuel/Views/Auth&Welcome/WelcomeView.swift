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
    @State private var googleError: String?
    @State private var isAppleLoading = false
    @State private var appleError: String?
    @State private var appleNonce: String?

    var body: some View {
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

                Text("Fuel your training with personalised macros, meal timing, and AI-powered logging.")
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
                .frame(height: 48)
                .frame(maxWidth: .infinity)
                .opacity(0.02)
                .overlay(
                    socialButtonLabel(
                        icon: appleIcon,
                        text: isAppleLoading ? "Connecting…" : "Continue with Apple",
                        isLoading: isAppleLoading
                    )
                    .allowsHitTesting(false)
                )
                .disabled(isAppleLoading)

                if let appleError {
                    Text(appleError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

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

                if let googleError {
                    Text(googleError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    onSignUp()
                } label: {
                    Text("Sign up")
                        .font(.headline).bold()
                        .foregroundStyle(.white)
                        .frame(height: 48)
                        .frame(maxWidth: .infinity)
                        .background(colorScheme == .light ? Color.black : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(colorScheme == .dark ? Color(.secondarySystemBackground) : .black, lineWidth: 1))
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

    @MainActor
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        guard !isAppleLoading else { return }
        appleError = nil
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
            try await authManager.signInWithApple(idTokenString: tokenString, rawNonce: rawNonce)
        } catch {
            appleError = (error as? AuthManagerError)?.localizedDescription ?? error.localizedDescription
        }
    }

    @MainActor
    private func handleGoogleSignIn() async {
        guard !isGoogleLoading else { return }
        googleError = nil
        isGoogleLoading = true
        defer { isGoogleLoading = false }

        do {
            try await authManager.signInWithGoogle()
        } catch {
            googleError = (error as? AuthManagerError)?.localizedDescription ?? error.localizedDescription
        }
    }

    private var socialBackground: Color {
        colorScheme == .light ? Color(.systemBackground) : Color(.secondarySystemBackground)
    }

    private var socialBorder: Color {
        colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.12)
    }

    private var googleIcon: some View {
        Text("G")
            .font(.title3.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(Color.liftEatsCoral, in: Circle())
    }

    private var appleIcon: some View {
        let bg = colorScheme == .dark ? Color.white.opacity(0.9) : Color.black
        let fg = colorScheme == .dark ? Color.black : Color.white
        return Image(systemName: "applelogo")
            .font(.headline.weight(.semibold))
            .foregroundStyle(fg)
            .frame(width: 26, height: 26)
            .background(bg, in: Circle())
    }

    private func socialButtonLabel(icon: some View, text: String, isLoading: Bool) -> some View {
        ZStack {
            HStack(spacing: 10) {
                icon

                Spacer()

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Color.clear
                        .frame(width: 16, height: 16)
                }
            }

            Text(text)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(height: 48)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(socialBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(socialBorder, lineWidth: 1)
        )
    }
}


#Preview {
    WelcomeView(onSignIn: {print("")}, onSignUp: { print("")})
        .environmentObject(FirebaseAuthManager())
}
