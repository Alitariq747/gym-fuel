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
                Color(red: 0.988, green: 0.982, blue: 0.955),
                Color(red: 0.983, green: 0.972, blue: 0.948),
                Color(red: 0.982, green: 0.979, blue: 0.970)
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
