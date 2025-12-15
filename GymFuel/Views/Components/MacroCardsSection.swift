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
    
    private var caloriesProgress: Double {
        let target = targets.calories
        guard target > 0 else { return 0 }
        return min(max(consumed.calories / target, 0), 1) // 0...1
    }

    private var caloriesBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(.secondarySystemBackground))
                Capsule()
                    .fill(caloriesTint)
                    .frame(width: geo.size.width * caloriesProgress)
                    .animation(.spring(response: 0.45, dampingFraction: 0.9), value: caloriesProgress)
                    .animation(.easeInOut(duration: 0.20), value: caloriesIsOver)
            }
        }
        .frame(height: 10)
    }
    
    private var proteinProgress: Double {
        let targetProtein = targets.protein
        guard targetProtein > 0 else { return 0 }
        return min(max(consumed.protein / targetProtein, 0), 1)
    }
    
    private var caloriesIsOver: Bool {
        targets.calories > 0 && consumed.calories > targets.calories
    }

    private var caloriesTint: Color {
        caloriesIsOver ? .red : .liftEatsCoral
    }



    var body: some View {
        
        
        
        VStack(alignment: .leading, spacing: 8) {
          
            Text("Macros")
                .font(.headline).bold()
        
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(caloriesTint)
                        .animation(.easeInOut(duration: 0.20), value: caloriesIsOver)
                    Text("Calories")
                    Spacer()
                    Text("\(Int(consumed.calories)) / \(Int(targets.calories))")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline.weight(.semibold))

                caloriesBar
            }


            HStack(alignment: .center, spacing: 24) {
                MacroRingView(
                    title: "Protein",
                    unit: "g",
                    target: targets.protein,
                    consumed: consumed.protein,
                    image: "fish.fill",
                    color: Color.indigo.opacity(0.8)
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
            .padding(.top, 18)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        
    }
}

#Preview {
    ZStack {
        AppBackground()
        MacroCardsSection(targets: Macros(calories: 2000, protein: 150, carbs: 100, fat: 50), consumed: Macros(calories: 100, protein: 160, carbs: 65, fat: 115))
    }
}
