//
//  ProfileView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/01/2026.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var profileVm: UserProfileViewModel
    @EnvironmentObject private var authManager: FirebaseAuthManager
    
    @State private var draft: UserProfileDraft? = nil
    
    var body: some View {
        ZStack {
             AppBackground()

            Group {
                if profileVm.profile != nil {
                    if let draftBinding = Binding($draft) {
                        ProfileEditorView(draft: draftBinding, email: authManager.user?.email)
                    } else {
                        ProgressView("Getting Editor")
                    }
                } else if profileVm.isLoading {
                    ProgressView("Loading Profile")
                } else {
                    Text(profileVm.errorMessage ?? "No profile available")
                        .padding()
                        .font(.subheadline)
                        .foregroundStyle(.red.opacity(0.7))
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task(id: profileVm.profile?.id) {
            if let profile = profileVm.profile {
                draft = UserProfileDraft(from: profile)
            } else {
                draft = nil
            }
        }
    }
}

#Preview {
    let auth = FirebaseAuthManager()
    let profileVM = UserProfileViewModel()
    profileVM._setProfileForPreview(dummyProfile)

    return ProfileView()
        .environmentObject(auth)
        .environmentObject(profileVM)
}


