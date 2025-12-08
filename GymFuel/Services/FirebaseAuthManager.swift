//
//  FirebaseAuthManager.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import Foundation
import FirebaseAuth

final class FirebaseAuthManager: ObservableObject {
    @Published var user: User?
    
    static let shared = FirebaseAuthManager()
    
    private init() {
        self.user = Auth.auth().currentUser
        Auth.auth().addStateDidChangeListener { _, user in
            Task {
                @MainActor in
                self.user = user
            }
        }
    }
    
    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        await MainActor.run {
            self.user = result.user
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await MainActor.run {
            self.user = result.user
        }    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        self.user = nil
    }
}
