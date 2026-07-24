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
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    @AppStorage("appColorSchemePreference") private var colorSchemePreference = AppColorSchemePreference.system.rawValue

    private var preferredColorScheme: ColorScheme? {
        AppColorSchemePreference(rawValue: colorSchemePreference)?.colorScheme
    }
    
    init() {
        AppCheck.setAppCheckProviderFactory(LiftEatsAppCheckProviderFactory())
        FirebaseApp.configure()
        SubscriptionService.shared.configureIfNeeded()

        Task.detached {
            _ = try? await SubscriptionService.shared.paywallPackages()
        }
    }
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(profileViewModel)
                .environmentObject(subscriptionViewModel)
                .preferredColorScheme(preferredColorScheme)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
            
        }
    }
}
