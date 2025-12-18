//
//  MainTabView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var dayLogViewModel: DayLogViewModel
    
   
    @State private var selectedDate: Date = Date()
    
    init(profile: UserProfile) {
        _dayLogViewModel = StateObject(wrappedValue: DayLogViewModel(profile: profile))
    }
    
    var body: some View {
        NavigationStack {
                TodayView(viewModel: dayLogViewModel, selectedDate: $selectedDate)
        }
 
    }
}

#Preview {
    MainTabView(profile: dummyProfile)
}
