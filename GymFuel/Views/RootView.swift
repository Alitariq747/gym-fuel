//
//  RootTabView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import SwiftUI

struct RootView: View {
    
    @StateObject private var authManager = FirebaseAuthManager.shared
    
    var body: some View {
        Group {
            if authManager.user == nil {
                AuthView()
            } else {
                MainTabView()
            }
        }
    }
}

#Preview {
    RootView()
}
