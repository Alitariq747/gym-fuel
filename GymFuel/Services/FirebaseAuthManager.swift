//
//  FirebaseAuthManager.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

// FirebaseAuthManager.swift

import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFunctions
import GoogleSignIn
import AuthenticationServices
import UIKit
import CryptoKit

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
            GIDSignIn.sharedInstance.signOut()
            self.user = nil
        } catch {
            throw mapFirebaseAuthError(error)
        }
    }

    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthManagerError.unknown
        }

        let config = GIDConfiguration(clientID: clientID)
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            throw AuthManagerError.unknown
        }

        do {
            GIDSignIn.sharedInstance.configuration = config
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthManagerError.unknown
            }
            let accessToken = result.user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            self.user = authResult.user
        } catch {
            throw error
        }
    }

    func signInWithApple(idTokenString: String, rawNonce: String) async throws {
        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: idTokenString,
            rawNonce: rawNonce
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        self.user = authResult.user
    }

    func deleteAccount() async throws {
        let deletionService = FirebaseAccountDeletionService()

        do {
            try await deletionService.deleteCurrentAccount()

            // Keep client-side state consistent even if the backend already removed auth.
            try? Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.user = nil
        } catch {
            let nsError = error as NSError
            if nsError.domain == FunctionsErrorDomain,
               let code = FunctionsErrorCode(rawValue: nsError.code) {
                switch code {
                case .unauthenticated:
                    throw AuthManagerError.invalidCredential
                case .permissionDenied:
                    throw AuthManagerError.operationNotAllowed
                case .resourceExhausted:
                    throw AuthManagerError.tooManyRequests
                case .unavailable:
                    throw AuthManagerError.networkError
                default:
                    throw AuthManagerError.unknown
                }
            }

            throw mapFirebaseAuthError(error)
        }
    }

    func reauthenticateForDeleteWithEmail(email: String, password: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthManagerError.invalidCredential
        }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedEmail.isEmpty else {
            throw AuthManagerError.missingEmail
        }

        guard !password.isEmpty else {
            throw AuthManagerError.missingPassword
        }

        let credential = EmailAuthProvider.credential(
            withEmail: normalizedEmail,
            password: password
        )

        do {
            _ = try await currentUser.reauthenticate(with: credential)
        } catch {
            throw mapFirebaseAuthError(error)
        }
    }

    func reauthenticateForDeleteWithGoogle() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthManagerError.invalidCredential
        }

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthManagerError.unknown
        }

        guard let rootVC = keyWindowRootViewController() else {
            throw AuthManagerError.unknown
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthManagerError.unknown
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            _ = try await currentUser.reauthenticate(with: credential)
        } catch {
            throw mapFirebaseAuthError(error)
        }
    }

    func reauthenticateForDeleteWithApple(idTokenString: String, rawNonce: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthManagerError.invalidCredential
        }

        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: idTokenString,
            rawNonce: rawNonce
        )

        do {
            _ = try await currentUser.reauthenticate(with: credential)
        } catch {
            throw mapFirebaseAuthError(error)
        }
    }

    func reauthenticateForDeleteWithApple(
        authorization: ASAuthorization,
        rawNonce: String
    ) async throws {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = appleCredential.identityToken,
              let tokenString = String(data: tokenData, encoding: .utf8) else {
            throw AuthManagerError.unknown
        }

        guard let authCodeData = appleCredential.authorizationCode,
              let authCodeString = String(data: authCodeData, encoding: .utf8),
              !authCodeString.isEmpty else {
            throw AuthManagerError.missingAppleAuthorizationCode
        }

        try await reauthenticateForDeleteWithApple(
            idTokenString: tokenString,
            rawNonce: rawNonce
        )

        do {
            // Required by Apple for in-app account deletion compliance.
            try await Auth.auth().revokeToken(withAuthorizationCode: authCodeString)
        } catch {
            throw mapFirebaseAuthError(error)
        }
    }

    func generateNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if status != errSecSuccess {
                continue
            }

            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }

        return result
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
    
   
    
    private func mapFirebaseAuthError(_ error: Error) -> AuthManagerError {
        let nsError = error as NSError

        // Avoid relying on SDK enum availability across GoogleSignIn versions.
        // In Google Sign-In, user-cancel is NSError code -5.
        if nsError.domain.localizedCaseInsensitiveContains("gidsignin") {
            return nsError.code == -5 ? .operationCancelled : .unknown
        }

        if nsError.domain == ASAuthorizationError.errorDomain,
           let code = ASAuthorizationError.Code(rawValue: nsError.code),
           code == .canceled {
            return .operationCancelled
        }

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
    case missingAppleAuthorizationCode
    case operationCancelled
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
        case .missingAppleAuthorizationCode:
            return "Couldn't verify your Apple session. Please try again."
        case .operationCancelled:
            return "Operation cancelled."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}

private extension FirebaseAuthManager {
    func keyWindowRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })?
            .rootViewController
    }
}
