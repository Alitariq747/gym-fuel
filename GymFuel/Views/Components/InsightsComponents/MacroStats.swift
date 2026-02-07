//
//  MacroStats.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 21/01/2026.
//

import SwiftUI

struct MacroStats: View {
    
    let averageFuelScore: Int?
    let trainingDaysPlanned: Int
    let trainingDaysCompleted: Int
    let restDays: Int
    let highScoreDays: Int
    
    var body: some View {
        VStack(spacing: 2) {
            
            //HStack for average fuel score
            HStack(alignment: .center, spacing: 4) {
                Text("Average Fuel Score: ")
                    .font(.subheadline.weight(.medium))
                Text(averageFuelScore.map(String.init) ?? "—")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(averageFuelScore == nil ? .secondary : .primary)
                Text("/ 100")
                    .font(.subheadline.weight(.regular))
            }
            Divider()
                .padding(.horizontal)
                .padding(.bottom, 8)
            
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
                
                HStack(alignment: .center, spacing: 4) {
                    Text("Days > 75: ")
                        .font(.caption.weight(.medium))
                    Text("\(highScoreDays)")
                        .font(.title3.weight(.semibold))
                    
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.fuelOrange.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
        }

    }
}

#Preview {
    MacroStats(averageFuelScore: 75, trainingDaysPlanned: 5, trainingDaysCompleted: 3, restDays: 2, highScoreDays: 2)
}
