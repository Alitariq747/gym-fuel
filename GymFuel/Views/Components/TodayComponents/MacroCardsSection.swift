//
//  MacroCardsSection.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/12/2025.
//
import SwiftUI

struct MacroCardsSection: View {
    let targets: Macros
    let consumed: Macros
    

    var body: some View {
        
        
        
        VStack(alignment: .leading, spacing: 12) {
          
        // Calories Text
            VStack(alignment: .center) {
                Text("Calories")
                    .font(.headline)
                HStack(spacing: 0) {
                    Text("\(Int(consumed.calories)) / ")
                        .font(.title).bold()
                    
                    Text("\(Int(targets.calories))")
                        .font(.title).bold()
                        .foregroundStyle(.secondary)
                }
 
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)

            HStack(alignment: .center, spacing: 12) {
                
                MacroRingView(
                    title: "Protein",
                    unit: "g",
                    target: targets.protein,
                    consumed: consumed.protein,
                    image: "fish.fill",
                    color: Color.green.opacity(0.8)
                )

                MacroRingView(
                    title: "Carbs",
                    unit: "g",
                    target: targets.carbs,
                    consumed: consumed.carbs,
                    image: "leaf.fill",
                    color: Color.orange.opacity(0.8)
                )

                MacroRingView(
                    title: "Fat",
                    unit: "g",
                    target: targets.fat,
                    consumed: consumed.fat,
                    image: "drop.fill",
                    color: Color.cyan
                )
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }

    }
}

#Preview {
    ZStack {
        AppBackground()
        MacroCardsSection(targets: Macros(calories: 2000, protein: 150, carbs: 300, fat: 50), consumed: Macros(calories: 1000, protein: 130, carbs: 165, fat: 45))
    }
}
