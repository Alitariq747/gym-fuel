//
//  SignIn.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 13/12/2025.
//

import SwiftUI

struct SignInView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: FirebaseAuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var showResetPasswordSheet = false
    @State private var resetEmail = ""
    @State private var resetMessage: String?
    @State private var showResetLinkSentAlert = false
    @State private var isSendingResetLink = false
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "figure.strengthtraining.traditional.circle.fill")
                .renderingMode(.original)
                .font(.system(size: 70, weight: .bold))
                .foregroundStyle(colorScheme == .light ? .black : Color(.secondarySystemBackground))
              
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Email")
                        .font(.subheadline)
                    TextField("", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.leading, 12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Password")
                            .font(.subheadline)
                        Spacer()
                        Button("Forgot?") {
                            resetEmail = email
                            resetMessage = nil
                            showResetPasswordSheet = true
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.fuelRed)
                        .disabled(isLoading)
                    }
                    SecureField("", text: $password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.leading, 12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
            Button {
                Task {
                    await signIn()
                }
            } label: {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(isLoading ? "Signing in…" : "Log in")
                        .font(.headline).bold()
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)
                .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.black, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

        }
        .padding()
        .navigationTitle("Welcome Back")
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .background(Color(.secondarySystemBackground), in: Circle())
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showResetPasswordSheet) {
            resetPasswordSheet
                .presentationDetents([.height(430)])
                .presentationDragIndicator(.visible)
        }
        .alert("Reset link sent", isPresented: $showResetLinkSentAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text( "A password reset link has been sent to your provided email.")
        }
    }

    private var resetPasswordSheet: some View {
        VStack(spacing: 12) {
            Image("LiftEatsWelcomeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 58, height: 58)
            Text("Reset Password")
                .font(.title3.weight(.semibold))
            Text("Enter your email to receive a reset link.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 4) {
                Text("Email")
                    .font(.subheadline)
                TextField("", text: $resetEmail)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.vertical, 12)
                    .padding(.leading, 12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator).opacity(0.45), lineWidth: 1)
                    )
            }
            if let resetMessage {
                Text(resetMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                Task { await sendResetLink() }
            } label: {
                Text(isSendingResetLink ? "Sending..." : "Send Reset Link")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.black, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(isSendingResetLink)
        }
        .padding(24)
    }

    private func sendResetLink() async {
        guard !isSendingResetLink else { return }
        resetMessage = nil
        isSendingResetLink = true
        defer { isSendingResetLink = false }

        do {
            try await authManager.sendPasswordReset(email: resetEmail)
            showResetPasswordSheet = false
            showResetLinkSentAlert = true
        } catch {
            resetMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't send a reset link. Please try again."
            )
        }
    }

    private func signIn() async {
        guard !isLoading else { return }
        errorMessage = nil
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await authManager.signIn(email: email, password: password)
            errorMessage = nil
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't sign you in. Please try again."
            )
        }
    }
}


#Preview {
    SignInView()
}
