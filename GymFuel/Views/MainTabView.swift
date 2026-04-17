//
//  MainTabView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import SwiftUI

struct MainTabView: View {
    let profile: UserProfile
    @State private var showProfile = false
    @State private var showSavedMeals = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("LiftEats is being rebuilt around goal-fit meal feedback.")
                    .font(.title3.weight(.semibold))

                Text("Auth, onboarding, profile, and saved meals are staying in place while the old Today and Insights flows are being removed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("Open Profile") {
                    showProfile = true
                }
                .buttonStyle(.borderedProminent)

                Button("Open Saved Meals") {
                    showSavedMeals = true
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
            .navigationTitle("LiftEats")
        }
        .sheet(isPresented: $showProfile) {
            NavigationStack { ProfileView() }
        }
        .sheet(isPresented: $showSavedMeals) {
            SavedMealsSheet()
        }
    }
}

#Preview {
    let auth = FirebaseAuthManager()
    let profileVM = UserProfileViewModel()
    profileVM._setProfileForPreview(dummyProfile)

    return MainTabView(profile: dummyProfile)
        .environmentObject(auth)
        .environmentObject(profileVM)
}

