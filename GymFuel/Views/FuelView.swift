//
//  FuelView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import SwiftUI

struct FuelView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Fuel")
                    .font(.title.bold())
                Text("Plan meals and track nutrition.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("Fuel")
        }
    }
}

#Preview {
    FuelView()
}
