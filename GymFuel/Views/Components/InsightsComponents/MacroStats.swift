//
//  MacroStats.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 21/01/2026.
//

import SwiftUI

struct MacroStats: View {
    
    let trainingDaysPlanned: Int
    let trainingDaysCompleted: Int
    let restDays: Int
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                // HStack for training days
                HStack(alignment: .center, spacing: 4) {
                    Text("Training: ")
                        .font(.caption.weight(.medium))
                    Text("\(trainingDaysCompleted) / ")
                        .font(.title3.weight(.semibold))
                    Text("\(trainingDaysPlanned)")
                        .font(.subheadline.weight(.regular))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.fuelGreen.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
                
                // HStack for Rest Days
                HStack(alignment: .center, spacing: 4) {
                    Text("Rest Days: ")
                        .font(.caption.weight(.medium))
                    Text("\(restDays)")
                        .font(.title3.weight(.semibold))
                    
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.fuelBlue.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
        }

    }
}

#Preview {
    MacroStats(trainingDaysPlanned: 5, trainingDaysCompleted: 3, restDays: 2)
}
