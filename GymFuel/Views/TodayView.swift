//
//  TodayView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

// TodayView.swift
// GymFuel

import SwiftUI

struct TodayView: View {
    @ObservedObject var viewModel: DayLogViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    if let dayLog = viewModel.dayLog {
                        fuelScoreCard(dayLog: dayLog)
                        trainingSettingsCard(dayLog: dayLog)   // ← NEW

                        targetsCard(dayLog: dayLog)
                        timingCard(dayLog: dayLog)
                        mealsSection(dayLog: dayLog)
                        
                        debugButtons(dayLog: dayLog)
                    } else {
                        Text("Loading today’s log…")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Today")
            .task {
                await viewModel.createOrLoadTodayLog()
            }
        }
    }
    fileprivate let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .short
        return df
    }()

}

private extension TodayView {
    
    @ViewBuilder
    func fuelScoreCard(dayLog: DayLog) -> some View {
        let score = dayLog.fuelScore
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Fuel Score")
                .font(.headline)
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(score?.total ?? 0)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                
                Text("/ 100")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            
            if let score = score {
                HStack {
                    Text("Macros: \(score.macroAdherence)")
                    Spacer()
                    Text("Timing: \(score.timingAdherence)")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            } else {
                Text("No score yet. Log a meal to get started.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private extension TodayView {
    
    @ViewBuilder
    func targetsCard(dayLog: DayLog) -> some View {
        let targets = dayLog.macroTargets
        let consumed = viewModel.consumedMacros
        let remaining = viewModel.remainingMacros ?? .zero
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Macros")
                .font(.headline)
            
            macroRow(label: "Calories",
                     target: targets.calories,
                     consumed: consumed.calories,
                     remaining: remaining.calories,
                     unit: "kcal")
            
            macroRow(label: "Protein",
                     target: targets.protein,
                     consumed: consumed.protein,
                     remaining: remaining.protein,
                     unit: "g")
            
            macroRow(label: "Carbs",
                     target: targets.carbs,
                     consumed: consumed.carbs,
                     remaining: remaining.carbs,
                     unit: "g")
            
            macroRow(label: "Fat",
                     target: targets.fat,
                     consumed: consumed.fat,
                     remaining: remaining.fat,
                     unit: "g")
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    func macroRow(
        label: String,
        target: Double,
        consumed: Double,
        remaining: Double,
        unit: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Int(consumed))/\(Int(target)) \(unit)")
                    .font(.subheadline)
            }
            
            ProgressView(
                value: min(consumed, target),
                total: max(target, 1)
            )
            .tint(.accentColor)
            
            Text("Remaining: \(Int(remaining)) \(unit)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private extension TodayView {
    
    @ViewBuilder
    func timingCard(dayLog: DayLog) -> some View {
        let pre = viewModel.preWorkoutMacros
        let post = viewModel.postWorkoutMacros
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Workout Fuel Windows")
                .font(.headline)
            
            if dayLog.isTrainingDay, let sessionStart = dayLog.sessionStart {
                
                Text("Session at \(timeFormatter.string(from: sessionStart))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Rest day – timing less critical.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Pre-workout")
                    .font(.subheadline.weight(.medium))
                Text("Carbs: \(Int(pre.carbs)) g • Protein: \(Int(pre.protein)) g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Post-workout")
                    .font(.subheadline.weight(.medium))
                Text("Carbs: \(Int(post.carbs)) g • Protein: \(Int(post.protein)) g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private extension TodayView {
    
    @ViewBuilder
    func mealsSection(dayLog: DayLog) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meals")
                .font(.headline)
            
            if viewModel.meals.isEmpty {
                Text("No meals logged yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.meals) { meal in
                    mealRow(meal: meal, dayLog: dayLog)
                    Divider()
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    func mealRow(meal: Meal, dayLog: DayLog) -> some View {
        let tag = meal.timingTag(
            relativeTo: dayLog.sessionStart,
            isTrainingDay: dayLog.isTrainingDay
        )
        
   
        
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(timeFormatter.string(from: meal.loggedAt))
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(timingLabel(for: tag))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(tagBackground(for: tag))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            
            Text(meal.description)
                .font(.subheadline)
            
            Text("\(Int(meal.macros.calories)) kcal • P \(Int(meal.macros.protein)) • C \(Int(meal.macros.carbs)) • F \(Int(meal.macros.fat))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    func timingLabel(for tag: MealTimingTag) -> String {
        switch tag {
        case .preWorkout: return "Pre-workout"
        case .postWorkout: return "Post-workout"
        case .otherOnTrainingDay: return "Other"
        case .restDay: return "Rest day"
        }
    }
    
    func tagBackground(for tag: MealTimingTag) -> Color {
        switch tag {
        case .preWorkout: return .blue
        case .postWorkout: return .green
        case .otherOnTrainingDay: return .gray
        case .restDay: return .orange
        }
    }
}

private extension TodayView {
    
    @ViewBuilder
    func debugButtons(dayLog: DayLog) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Debug")
                .font(.headline)
            
            HStack {
                Button("Add pre-workout test meal") {
                    Task {
                        let date = Calendar.current.date(
                            byAdding: .hour,
                            value: -2,
                            to: dayLog.sessionStart ?? Date()
                        ) ?? Date()
                        
                        await viewModel.addMeal(
                            description: "Test pre-workout meal",
                            macros: Macros(calories: 400, protein: 25, carbs: 60, fat: 10),
                            loggedAt: date
                        )
                    }
                }
                
                Button("Add post-workout test meal") {
                    Task {
                        let date = Calendar.current.date(
                            byAdding: .hour,
                            value: 1,
                            to: dayLog.sessionStart ?? Date()
                        ) ?? Date()
                        
                        await viewModel.addMeal(
                            description: "Test post-workout meal",
                            macros: Macros(calories: 300, protein: 30, carbs: 30, fat: 5),
                            loggedAt: date
                        )
                    }
                }
            }
            .font(.caption)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private extension TodayView {
    
    @ViewBuilder
    func trainingSettingsCard(dayLog: DayLog) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Settings")
                .font(.headline)
            
            // 1) Training day toggle
            // 1) Training day toggle
            Toggle("Today is a training day",
                   isOn: Binding<Bool>(
                       get: {
                           viewModel.dayLog?.isTrainingDay ?? dayLog.isTrainingDay
                       },
                       set: { newValue in
                           viewModel.setIsTrainingDay(newValue)
                       }
                   )
            )

           

            
            // 2) Training intensity picker (segmented)
            VStack(alignment: .leading, spacing: 4) {
                Text("Intensity")
                    .font(.subheadline.weight(.medium))
                
                let currentIntensity = viewModel.dayLog?.trainingIntensity
                    ?? dayLog.trainingIntensity
                    ?? .normal
                
                Picker("Intensity", selection: Binding(
                    get: { currentIntensity },
                    set: { newValue in
                        viewModel.setTrainingIntensity(newValue)
                    }
                )) {
                    Text("Recovery").tag(TrainingIntensity.recovery)
                    Text("Normal").tag(TrainingIntensity.normal)
                    Text("Hard").tag(TrainingIntensity.hard)
                    Text("All-out").tag(TrainingIntensity.allOut)
                }
                .pickerStyle(.segmented)
            }
            
            // 3) Session type picker (segmented)
            VStack(alignment: .leading, spacing: 4) {
                Text("Session type")
                    .font(.subheadline.weight(.medium))
                
                let currentType = viewModel.dayLog?.sessionType
                    ?? dayLog.sessionType
                    ?? .strength   // fallback
                
                Picker("Session type", selection: Binding(
                    get: { currentType },
                    set: { newValue in
                        viewModel.setSessionType(newValue)
                    }
                )) {
                    Text("Strength").tag(SessionType.strength)
                    Text("Hypertrophy").tag(SessionType.hypertrophy)
                    Text("Mixed").tag(SessionType.mixed)
                    Text("Endurance").tag(SessionType.endurance)
                }
                .pickerStyle(.segmented)
            }
            
            // 4) Session time picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Session time")
                    .font(.subheadline.weight(.medium))
                
                let currentTime = viewModel.dayLog?.sessionStart
                    ?? dayLog.sessionStart
                    ?? Date()
                
                DatePicker(
                    "Start",
                    selection: Binding(
                        get: { currentTime },
                        set: { newValue in
                            viewModel.setSessionStart(newValue)
                        }
                    ),
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.compact)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}




//#Preview {
//    TodayView(viewModel: DayLogViewModel())
//}

