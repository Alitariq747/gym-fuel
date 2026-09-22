//
//  SignIn.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 13/12/2025.
//

import SwiftUI

struct SignInView: View {
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
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    CircaSectionLabel("Your account")
                    Text("Welcome back")
                        .font(.circaTitle)
                        .foregroundStyle(Color.circaInk)
                    Text("Pick up where you left off in your food journal.")
                        .font(.circaBody)
                        .foregroundStyle(Color.circaInk2)
                }

                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Email")
                        .font(.circaRow)
                        .foregroundStyle(Color.circaInk2)
                    TextField("Email address", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .authFieldStyle()

                    HStack {
                        Text("Password")
                            .font(.circaRow)
                            .foregroundStyle(Color.circaInk2)
                        Spacer()
                        Button("Forgot?") {
                            resetEmail = email
                            resetMessage = nil
                            showResetPasswordSheet = true
                        }
                        .font(.circaCaption.weight(.semibold))
                        .foregroundStyle(Color.circaAccent)
                        .frame(minHeight: Circa.minHitTarget)
                        .disabled(isLoading)
                    }
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .authFieldStyle()
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaDanger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 24)

                Button {
                    Task { await signIn() }
                } label: {
                    HStack(spacing: 10) {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(isLoading ? "Signing in…" : "Sign in")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary, height: 52))
                .disabled(isLoading)
            }
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.top, 28)
            .padding(.bottom, 24)
        }
        .circaPaper()
        .navigationTitle("")
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.circaInk)
                        .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                        .background(Color.circaCard, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }
        }
        .sheet(isPresented: $showResetPasswordSheet) {
            resetPasswordSheet
                .presentationDetents([.height(430), .large])
                .presentationDragIndicator(.visible)
        }
        .alert("Reset link sent", isPresented: $showResetLinkSentAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text( "A password reset link has been sent to your provided email.")
        }
    }

    private var resetPasswordSheet: some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    CircaSectionLabel("Password help")
                    Spacer()
                    Button {
                        showResetPasswordSheet = false
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.circaInk2)
                    .accessibilityLabel("Close")
                }

                Text("Reset your password")
                    .font(.circaTitle)
                    .foregroundStyle(Color.circaInk)
                Text("Enter your email and we'll send you a reset link.")
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)

                Text("Email")
                    .font(.circaRow)
                    .foregroundStyle(Color.circaInk2)
                TextField("Email address", text: $resetEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .authFieldStyle()

                if let resetMessage {
                    Text(resetMessage)
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaDanger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    Task { await sendResetLink() }
                } label: {
                    Text(isSendingResetLink ? "Sending…" : "Send reset link")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary, height: 52))
                .disabled(isSendingResetLink)
            }
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .circaPaper()
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
