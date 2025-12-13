//
//  AuthView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import SwiftUI



struct AuthView: View {
    @EnvironmentObject private var authManager: FirebaseAuthManager
    
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
                    await handleAuth(isSignUp: false)
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Sign Up") {
                Task {
                    await handleAuth(isSignUp: true)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func handleAuth(isSignUp: Bool) async {
        // Simple local validation first
        guard !email.isEmpty, !password.isEmpty else {
            await MainActor.run {
                errorMessage = "Please enter both email and password."
            }
            return
        }
        
        do {
            if isSignUp {
                try await authManager.signUp(email: email, password: password)
            } else {
                try await authManager.signIn(email: email, password: password)
            }
            // If it succeeds, clear the error
            await MainActor.run {
                errorMessage = nil
            }
        } catch {
            await MainActor.run {
                if let authError = error as? AuthManagerError {
                    // Our custom friendly message
                    errorMessage = authError.localizedDescription
                } else {
                    // Fallback, just in case
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(FirebaseAuthManager())
}

