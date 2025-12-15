//
//  AuthFlowView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 13/12/2025.
//

import SwiftUI

enum AuthRoute: Hashable {
    case signIn
    case signUp
}


struct AuthFlowView: View {
    
    @State private var path: [AuthRoute] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(
                           onSignIn: { path.append(.signIn) },
                           onSignUp: { path.append(.signUp) }
            )
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .signIn:
                    SignInView()
                case .signUp:
                    SignUpView()
                }
            }

        }
    }
}

#Preview {
    AuthFlowView()
}
