//
//  MainTabView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "flame.fill")
                }
            LogView()
                .tabItem {
                    Label("Log", systemImage: "square.and.pencil")
                }
            FuelView()
                .tabItem {
                    Label("Fuel", systemImage: "gauge")
                }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
