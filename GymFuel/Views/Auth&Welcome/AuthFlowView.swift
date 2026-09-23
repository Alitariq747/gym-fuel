//
//  AuthFlowView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 13/12/2025.
//

import SwiftUI

enum AuthRoute: Hashable {
    case signInChoices
    case signInEmail
}


struct AuthFlowView: View {
    let onGetStarted: () -> Void
    @State private var path: [AuthRoute] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(
                onGetStarted: onGetStarted,
                onSignIn: { path.append(.signInChoices) }
            )
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .signInChoices:
                    AuthChoicesView(
                        mode: .signIn,
                        onBack: { _ = path.popLast() },
                        onEmail: { path.append(.signInEmail) },
                        onSignIn: nil,
                        onAuthenticated: { _ in }
                    )
                case .signInEmail:
                    SignInView()
                }
            }

        }
    }
}

#Preview {
    AuthFlowView(onGetStarted: { })
        .environmentObject(FirebaseAuthManager())
}
