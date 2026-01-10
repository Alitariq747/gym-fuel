//
//  AppBackground.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 14/12/2025.
//



import SwiftUI

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(.systemGray6),
                Color(.secondarySystemBackground),
                Color(.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}


#Preview {
    AppBackground()
}
