//
//  SignUpView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 13/12/2025.
//

import SwiftUI

struct SignUpView: View {
    var onAuthenticated: ((AuthAccountOutcome) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: FirebaseAuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    CircaSectionLabel("Your account")
                    Text("Create your account")
                        .font(.circaTitle)
                        .foregroundStyle(Color.circaInk)
                    Text("Keep your meals and corrections ready for next time.")
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

                    Text("Password")
                        .font(.circaRow)
                        .foregroundStyle(Color.circaInk2)
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
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
                    Task { await signUp() }
                } label: {
                    HStack(spacing: 10) {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(isLoading ? "Creating account…" : "Create account")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.circa(.primary, height: 52))
                .disabled(isLoading)

                LegalAgreementText(context: .creatingAccount)
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
    }

    private func signUp() async {
        guard !isLoading else { return }
        errorMessage = nil
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let outcome = try await authManager.signUp(email: email, password: password)
            errorMessage = nil
            onAuthenticated?(outcome)
        } catch {
            errorMessage = AppErrorMessage.message(
                for: error,
                fallback: "We couldn't create your account. Please try again."
            )
        }
    }
}

extension View {
    func authFieldStyle() -> some View {
        font(.circaRow)
            .foregroundStyle(Color.circaInk)
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .background(Color.circaCard, in: RoundedRectangle(cornerRadius: Circa.Radius.button))
            .overlay {
                RoundedRectangle(cornerRadius: Circa.Radius.button)
                    .strokeBorder(Color.circaCardBorder, lineWidth: Circa.Rule.hairline)
            }
    }
}


#Preview {
    SignUpView()
}
