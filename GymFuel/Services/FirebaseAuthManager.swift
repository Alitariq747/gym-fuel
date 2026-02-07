//
//  FirebaseAuthManager.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

// FirebaseAuthManager.swift

import Foundation
import FirebaseAuth

@MainActor
final class FirebaseAuthManager: ObservableObject {
    // UI can read this, but only this class can modify it
    @Published private(set) var user: User?
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
       
        self.user = Auth.auth().currentUser
        
        // Listen for sign-in / sign-out changes from Firebase
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }
    
    deinit {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
   
    
    func signUp(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.user = result.user
        } catch {
            // Convert Firebase NSError into our own error type
            throw mapFirebaseAuthError(error)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
        } catch {
            throw mapFirebaseAuthError(error)
        }
    }
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            self.user = nil
        } catch {
            throw mapFirebaseAuthError(error)
        }
    }
    
   
    
    private func mapFirebaseAuthError(_ error: Error) -> AuthManagerError {
        let nsError = error as NSError

        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return .unknown
        }

        switch code {
        case .invalidEmail:
            return .invalidEmail

        case .emailAlreadyInUse:
            return .emailAlreadyInUse

        case .weakPassword:
            return .weakPassword

        case .wrongPassword:
            return .wrongPassword

        case .userNotFound:
            return .userNotFound

        case .userDisabled:
            return .userDisabled

        case .invalidCredential:
            return .invalidCredential

        case .tooManyRequests:
            return .tooManyRequests

        case .networkError:
            return .networkError

        case .operationNotAllowed:
            return .operationNotAllowed

        default:
            return .unknown
        }
    }

}

/// Our own error type that we control and can show nice messages for.
enum AuthManagerError: LocalizedError {
    case invalidEmail
    case emailAlreadyInUse
    case weakPassword
    case wrongPassword
    case userNotFound
    case userDisabled
    case invalidCredential
    case tooManyRequests
    case networkError
    case operationNotAllowed
    case missingEmail
    case missingPassword
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .emailAlreadyInUse:
            return "This email is already in use. Try signing in instead."
        case .weakPassword:
            return "Password is too weak. It must be at least 6 characters."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .userNotFound:
            return "No account found with this email."
        case .userDisabled:
            return "This account has been disabled."
        case .invalidCredential:
            return "Incorrect email or password."
        case .tooManyRequests:
            return "Too many attempts. Please try again later."
        case .networkError:
            return "Network error. Check your connection and try again."
        case .operationNotAllowed:
            return "This sign-in method is not enabled."
        case .missingEmail:
            return "Please enter your email address."
        case .missingPassword:
            return "Please enter your password."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}
