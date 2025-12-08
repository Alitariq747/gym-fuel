//
//  AuthView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import SwiftUI

struct AuthView: View {
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    
    
    var body: some View {
        VStack(spacing: 16) {
                    Text("GymFuel")
                        .font(.largeTitle.bold())
                    
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                    
                    Button("Sign In") {
                        Task {
                            await handleSignIn(isSignUp: false)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Sign Up") {
                        Task {
                            await handleSignIn(isSignUp: true)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
    }
    
    private func handleSignIn(isSignUp: Bool) async {
        do {
            if (isSignUp) {
                try await FirebaseAuthManager.shared.signUp(email: email, password: password)
            } else {
                try await FirebaseAuthManager.shared.signIn(email: email, password: password)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    AuthView()
}
