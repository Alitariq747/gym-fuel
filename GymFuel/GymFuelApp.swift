//
//  GymFuelApp.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn
import FirebaseAppCheck

@main
struct GymFuelApp: App {
    @StateObject private var authManager = FirebaseAuthManager()
    @StateObject private var profileViewModel = UserProfileViewModel()
    
    init() {
        AppCheck.setAppCheckProviderFactory(LiftEatsAppCheckProviderFactory())
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(profileViewModel)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
            
        }
    }
}
