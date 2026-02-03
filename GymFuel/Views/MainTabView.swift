//
//  MainTabView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import SwiftUI

struct MainTabView: View {
    let profile: UserProfile
    @StateObject private var dayLogViewModel: DayLogViewModel
    @State private var selectedDate: Date = Date()
    
  
    
    init(profile: UserProfile) {
        self.profile = profile
        _dayLogViewModel = StateObject(wrappedValue: DayLogViewModel(profile: profile))
    }
    
    var body: some View {
        NavigationStack {
            TodayView(
                viewModel: dayLogViewModel,
                selectedDate: $selectedDate
            )
        }
        .onChange(of: profile) { _, newProfile in
            dayLogViewModel.updateProfile(newProfile)
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


