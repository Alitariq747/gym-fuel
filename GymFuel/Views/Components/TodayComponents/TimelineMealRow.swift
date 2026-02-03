//
//  TimelineMealRow.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/01/2026.
//

import SwiftUI



 struct TimelineMealRow: View {
    let meal: Meal
    let tag: MealTimingTag
    let impact: DayLogViewModel.MealFuelImpact?

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: meal.loggedAt)
    }
    
     private var impactDelta: Int? {
         guard let impact else { return nil }
         
         let delta = impact.totalDelta
         
         if abs(delta) <= 1 {
             return nil
         }
         
         return delta
     }


     private var isPositiveImpact: Bool {
         guard let delta = impactDelta else { return false }
         return delta > 0
     }

     private enum ImpactDriver {
         case macros
         case timing
     }

     private var impactDriver: ImpactDriver? {
         guard let impact, impact.totalDelta != 0 else { return nil }

         let macroAbs  = abs(impact.macroDelta)
         let timingAbs = abs(impact.timingDelta)

         if macroAbs == 0 && timingAbs == 0 { return nil }

         return macroAbs >= timingAbs ? .macros : .timing
     }

     private var impactValueText: String {
         guard let delta = impactDelta else { return "" }
         return delta > 0 ? "+\(delta)" : "\(delta)"
     }

     private var impactColor: Color {
         guard impactDelta != nil else { return .secondary }
         return isPositiveImpact ? .indigo : .red
     }

     private var impactIconName: String {
         guard impactDelta != nil else { return "minus.circle" }
         return isPositiveImpact ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
     }

     private var impactMessageText: String {
         guard let driver = impactDriver, let delta = impactDelta else { return "" }
         
         let isPositive = delta > 0

         switch (tag, driver, isPositive) {
             
         // PRE-WORKOUT
         case (.preWorkout, .timing, true):
             return "PRE LOCKED"
         case (.preWorkout, .timing, false):
             return "PRE LATE"
         case (.preWorkout, .macros, true):
             return "PRE FUELED"
         case (.preWorkout, .macros, false):
             return "PRE LIGHT"
             
         // POST-WORKOUT
         case (.postWorkout, .timing, true):
             return "RECOVERY ON"
         case (.postWorkout, .timing, false):
             return "RECOVERY LATE"
         case (.postWorkout, .macros, true):
             return "RECOVERY HIT"
         case (.postWorkout, .macros, false):
             return "RECOVERY LIGHT"
             
         // SUPPORT MEALS (otherOnTrainingDay)
         case (.otherOnTrainingDay, .timing, true):
             return "DAY FLOW"
         case (.otherOnTrainingDay, .timing, false):
             return "DAY CLUMPED"
         case (.otherOnTrainingDay, .macros, true):
             return "DAY STEADY"
         case (.otherOnTrainingDay, .macros, false):
             return "DAY LAGGING"
             
         // REST DAY
         case (.restDay, .timing, true):
             return "REST IN SYNC"
         case (.restDay, .timing, false):
             return "REST OFF BEAT"
         case (.restDay, .macros, true):
             return "REST ON"
         case (.restDay, .macros, false):
             return "REST OFF"
         }
     }


    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Top Row HStack
            HStack(alignment: .center) {
                // vStack for time and desc
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.secondary)
                        Text(timeText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(meal.description.truncated(to: 20, addEllipsis: true))
                        .font(.subheadline)
                }
                
                Spacer()
                
                //  Vstack for impact chip and message
                VStack(alignment: .trailing, spacing: 4) {
                    if let _ = impactDelta {
                        // Impact chip
                        HStack(alignment: .center, spacing: 4) {
                            Image(systemName: impactIconName)
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(impactColor)

                            Text(impactValueText)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(impactColor)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 26)
                                .fill(impactColor.opacity(0.12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 26)
                                .stroke(impactColor.opacity(0.25), lineWidth: 1)
                        )

                        // Impact message
                        Text(impactMessageText)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(impactColor)
                    } else {
                        // Neutral state: no visible score change
                        Text("NEUTRAL")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

            }
            
            Divider()
            
            HStack {
                Text("\(Int(meal.macros.calories)) KCAL")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                
                // HStack for other macros
                HStack(alignment: .center, spacing: 8) {
                    
                    HStack(alignment: .center, spacing: 4) {
                        Circle()
                               .fill(Color.green.opacity(0.8))
                               .frame(width: 8, height: 8)
                        Text("\(Int(meal.macros.protein))P")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    HStack(alignment: .center, spacing: 4) {
                        Circle()
                              .fill(Color.orange.opacity(0.8))
                              .frame(width: 8, height: 8)
                        Text("\(Int(meal.macros.carbs))C")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(alignment: .center, spacing: 4) {
                        Circle()
                              .fill(Color.cyan)
                              .frame(width: 8, height: 8)
                        Text("\(Int(meal.macros.fat))F")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                }

            }
        }
        .padding()
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color(.systemBackground), lineWidth: 1))
    }
}


#Preview {
    ZStack {
        AppBackground()
        TimelineMealRow(meal: Meal.demoMeals(forTrainingDay: DayLog.demoTrainingDay)[0], tag: .postWorkout, impact: DayLogViewModel.MealFuelImpact(totalDelta: 17, macroDelta: 20, timingDelta: 12))
    }
}
