//
//  ProfileView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/01/2026.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        ZStack {
            // AppBackground()

            VStack(alignment: .leading, spacing: 16) {
                Text("Profile")
                    .font(.system(size: 28, weight: .bold))

                Text("This screen will show your basic info, goals and preferences.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
        }
    }
}


#Preview {
    ProfileView()
}
