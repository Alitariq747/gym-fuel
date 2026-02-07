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

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "figure.strengthtraining.traditional.circle.fill")
                .renderingMode(.original)
                .font(.system(size: 70, weight: .bold))
                .foregroundStyle(colorScheme == .light ? .black : Color(.secondarySystemBackground))
              
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enter Email")
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
                    Text("Enter Password")
                        .font(.subheadline)
                    SecureField("", text: $password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.leading, 12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            Spacer()
            Button {
                Task {
                    await signIn()
                }
            } label: {
                Text("Log in")
                    .font(.headline).bold()
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.black, in: RoundedRectangle(cornerRadius: 12))
            }

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
    }

    private func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }
        do {
            try await authManager.signIn(email: email, password: password)
            errorMessage = nil
        } catch {
            errorMessage = (error as? AuthManagerError)?.localizedDescription ?? error.localizedDescription
        }
    }
}


#Preview {
    SignInView()
}
