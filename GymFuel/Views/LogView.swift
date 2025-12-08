//
//  LogView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import SwiftUI

struct LogView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Workout Log")
                    .font(.title.bold())
                Text("View and edit your recent workouts.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("Log")
        }
    }
}

#Preview {
    LogView()
}
