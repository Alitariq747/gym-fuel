//
//  ProfileViewModel.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import Foundation
import FirebaseAuth

final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func loadProfile() {
        guard let user = Auth.auth().currentUser else {
            self.errorMessage = "No user signed in"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let uid = user.uid
        let email = user.email ?? ""
        
        FirestoreUserService.shared.fetchProfile(uid: uid) { [weak self]  result in
            DispatchQueue.main.async {
                switch result {
                    
                case .success(let existingProfile):
                    if let existingProfile {
                        self?.isLoading = false
                        self?.profile = existingProfile
                    } else {
                        FirestoreUserService.shared.createDefaultUser(uid: uid, email: email) { result in
                            DispatchQueue.main.async {
                                self?.isLoading = false
                                switch result {
                                    
                                case .success(let newProfile):
                                    self?.profile = newProfile
                                case .failure(let error):
                                    self?.errorMessage = error.localizedDescription
                                }
                            }
                        }
                    }
                  
                case .failure(let error):
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
