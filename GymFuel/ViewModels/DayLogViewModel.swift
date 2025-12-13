//
//  DayLogViewModel.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 11/12/2025.
//

import Foundation

@MainActor
final class DayLogViewModel: ObservableObject {
    
    @Published private(set) var dayLog: DayLog? // todays daylog for current user if existed
    
    @Published private(set) var meals: [Meal] = [] // meals logged for today
    
    @Published private var isLoading: Bool = false
    @Published private var errorMessage: String?
    
    // Dependencies
    private let planner: MacrosPlanner
    private let profile: UserProfile
    private let dayLogService: DayLogService
    private let mealService: MealService
    
    init(profile: UserProfile, planner: MacrosPlanner = MacrosPlanner(), dayLogService: DayLogService = FirebaseDayLogService(), mealService: MealService = FirebaseMealService()) {
        self.profile = profile
        self.planner = planner
        self.dayLogService = dayLogService
        self.mealService = mealService
    }
    
    func defaultSessionStart(for date: Date) -> Date? {
        guard let timeOfDay = profile.trainingTimeOfDay else { return nil }
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        switch timeOfDay {
        case .morning:
            components.hour = 7
            components.minute = 0
            
        case .midday:
            components.hour = 13
            components.minute = 0
        case .evening:
            components.hour = 19
            components.minute = 0
            
        case .varies:
            return nil
        }
        return calendar.date(from: components)
        
    }
    
    func createOrLoadTodayLog(date: Date = Date()) async {
            isLoading = true
            errorMessage = nil
            
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let userId = profile.id
            
            do {
                // 1) Try to fetch an existing DayLog for today from Firestore.
                if var existing = try await dayLogService.fetchDayLog(for: userId, date: startOfDay) {
                    // Ensure date is normalized
                    existing.date = startOfDay
                    
                    // Recompute macro targets using the latest profile & planner logic.
                    let macros = try planner.planDailyMacros(profile: profile, dayLog: existing)
                    existing.macroTargets = macros
                    self.dayLog = existing
                    
                    // 1b)
                    do {
                        let loadedMeals = try await mealService.fetchMeals(for: userId, dayLogId: existing.id)
                        self.meals = loadedMeals
                    } catch {
                        self.meals = []
                        self.errorMessage = error.localizedDescription
                    }
                    
                    // Recompute fuel score based on current meals (if any).
                    refreshFuelScore()
                    
                    // Save updated targets/score back to Firestore.
                    try await dayLogService.saveDayLog(existing)
                    
                    isLoading = false
                    return
                }
            } catch {
                // If fetch fails (e.g. permission issue), record the error
                // but still attempt to create a local DayLog below.
                self.errorMessage = error.localizedDescription
            }
            
            // 2) No DayLog exists for today (or fetch failed) → create a new one locally.
            let newId = Self.dayId(for: startOfDay, userId: userId)
            let defaultSessionStart = defaultSessionStart(for: startOfDay)
            
            var newDayLog = DayLog(
                id: newId,
                userId: userId,
                date: startOfDay,
                isTrainingDay: true,
                sessionStart: defaultSessionStart,
                trainingIntensity: .normal,
                sessionType: nil,
                macroTargets: .zero,
                fuelScore: nil
            )
            
            do {
                let macros = try planner.planDailyMacros(profile: profile, dayLog: newDayLog)
                newDayLog.macroTargets = macros
                self.dayLog = newDayLog
                
                // Compute initial fuel score (will mostly reflect targets, meals likely empty).
                //2a)
                do {
                    let loadedMeals = try await mealService.fetchMeals(
                        for: userId,
                        dayLogId: newDayLog.id
                    )
                    self.meals = loadedMeals
                } catch {
                    self.meals = []
                    self.errorMessage = error.localizedDescription
                }
                
                refreshFuelScore()
                
                // Persist to Firestore (or queue offline).
                try await dayLogService.saveDayLog(newDayLog)
            } catch {
                self.errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    
    func setIsTrainingDay(_ isTrainingDay: Bool) {
        guard var current = dayLog else { return }
        
        current.isTrainingDay = isTrainingDay
        
        if !isTrainingDay {
            current.sessionType = nil
            current.sessionStart = nil
            current.trainingIntensity = nil
        } else if current.sessionStart == nil {
            current.sessionStart = defaultSessionStart(for: current.date)
        }
        recalculateTargets(for: &current)
    }
    
    func setTrainingIntensity(_ intensity: TrainingIntensity?) {
        guard var current = dayLog else { return }
        current.trainingIntensity = intensity
        recalculateTargets(for: &current)
    }
    
    func setSessionType(_ sessionType: SessionType?) {
        guard var current = dayLog else { return }
        current.sessionType = sessionType
        recalculateTargets(for: &current)
    }
    
    func setSessionStart(_ sessionStart: Date) {
        guard var current = dayLog else { return }
        current.sessionStart = sessionStart
        recalculateTargets(for: &current)
    }
    
    
    func recalculateTargets(for dayLog: inout DayLog) {
        
        do {
            let macros = try planner.planDailyMacros(profile: profile, dayLog: dayLog)
            dayLog.macroTargets = macros
            self.dayLog = dayLog
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
            self.dayLog = dayLog
        }
        refreshFuelScore()
    }
    
    private static func dayId(for date: Date, userId: String) -> String {
           let formatter = DateFormatter()
           formatter.dateFormat = "yyyy-MM-dd"
           let dayString = formatter.string(from: date)
           return "\(userId)_\(dayString)"
       }
    
    // computed property for consumed macros
    var consumedMacros: Macros {
        meals.reduce(.zero) { partial, meal in
            Macros(calories: partial.calories + meal.macros.calories,
                   protein: partial.protein + meal.macros.protein,
                   carbs: partial.carbs + meal.macros.carbs,
                   fat: partial.fat + meal.macros.fat)
        }
    }
    
    // computed property for remaining macros
    var remainingMacros: Macros? {
        guard let targets = dayLog?.macroTargets else { return nil }
        
        let consumed = consumedMacros
        
        return Macros (calories: max(0, targets.calories - consumed.calories),
                      protein: max(0, targets.protein - consumed.protein),
                      carbs: max(0, targets.carbs - consumed.carbs),
                      fat: max(0, targets.fat - consumed.fat))
        
    }
    
    // func to add a meal
    
    func addMeal(description: String, macros: Macros, loggedAt: Date = Date()) async {
        guard let currentDayLog = dayLog else {
            return
            // how we can create one here
        }
        
        let newMeal = Meal(id: UUID().uuidString, userId: profile.id, dayLogId: currentDayLog.id, loggedAt: loggedAt, description: description, macros: macros)
        meals.append(newMeal)
        refreshFuelScore()
        
        do {
            try await mealService.saveMeal(newMeal)
            
            if let updatedDayLog = dayLog {
                try await dayLogService.saveDayLog(updatedDayLog)
            }
        } catch {
            // If the write fails, we keep the local state (offline-friendly)
            // but record the error so UI can show something if needed.
            errorMessage = error.localizedDescription
        }
    }
    
    func removeMeal(_ meal: Meal) async {
        meals.removeAll { $0.id == meal.id }
        refreshFuelScore()
        
        do {
            try await mealService.deleteMeal(meal)
            
            if let updatedDayLog = dayLog {
                try await dayLogService.saveDayLog(updatedDayLog)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func resetMeals() {
        meals.removeAll()
        refreshFuelScore()
    }
    
    var mealsByTiming: [MealTimingTag: [Meal]] {
        
        let sessionStart = dayLog?.sessionStart
        let isTrainingDay = dayLog?.isTrainingDay ?? false
        
        // group the meals by their computed timing tag
        return Dictionary(grouping: meals) { meal in
            meal.timingTag(relativeTo: sessionStart, isTrainingDay: isTrainingDay)
        }
    }
    
    var preWorkoutMeals: [Meal] {
        mealsByTiming[.preWorkout] ?? []
    }
    
    var postWorkoutMeals: [Meal] {
        mealsByTiming[.postWorkout] ?? []
    }
    
    var otherTrainingDayMeals: [Meal] {
        mealsByTiming[.otherOnTrainingDay] ?? []
    }
    
    var restDayMeals: [Meal] {
        mealsByTiming[.restDay] ?? []
    }
    
    // helper func to compute macros for a sub set of meals
    func macros(for meals: [Meal]) -> Macros {
         meals.reduce(.zero) { partial, meal in
             Macros(
                 calories: partial.calories + meal.macros.calories,
                 protein:  partial.protein  + meal.macros.protein,
                 carbs:    partial.carbs    + meal.macros.carbs,
                 fat:      partial.fat      + meal.macros.fat
             )
         }
     }
    
    /// Total macros from meals in the pre-workout window.
      var preWorkoutMacros: Macros {
          macros(for: preWorkoutMeals)
      }
      
      /// Total macros from meals in the post-workout window.
      var postWorkoutMacros: Macros {
          macros(for: postWorkoutMeals)
      }
      
      /// Total macros from meals that are neither pre- nor post-workout on a training day.
      var otherTrainingDayMacros: Macros {
          macros(for: otherTrainingDayMeals)
      }
      
      /// Total macros from meals on a rest day (when there is no training).
      var restDayMacros: Macros {
          macros(for: restDayMeals)
      }
    
    func ratioScore(
         actual: Double,
         target: Double,
         tolerance: Double = 0.35
     ) -> Double {
         guard target > 0 else { return 100 } // nothing to hit, treat as fine
         
         let ratio = actual / target
         let diff = abs(1.0 - ratio)          // 0 = perfect; 0.1 = 10% off
         
         // Normalize: diff = 0 → 100, diff = tolerance → 0
         let normalized = max(0.0, 1.0 - diff / tolerance)
         return normalized * 100.0
     }
    
    /// Score (0–100) for how well total macros match targets.
    func macroAdherenceScore(
        targets: Macros,
        consumed: Macros
    ) -> Int {
        // Use a more forgiving tolerance so the score
        // starts increasing earlier as the user eats.
        let tol = 1.0
        
        let caloriesScore = ratioScore(
            actual: consumed.calories,
            target: targets.calories,
            tolerance: tol
        )
        let proteinScore = ratioScore(
            actual: consumed.protein,
            target: targets.protein,
            tolerance: tol
        )
        let carbsScore = ratioScore(
            actual: consumed.carbs,
            target: targets.carbs,
            tolerance: tol
        )
        let fatScore = ratioScore(
            actual: consumed.fat,
            target: targets.fat,
            tolerance: tol
        )
        
        let totalScore =
            caloriesScore * 0.4 +
            proteinScore  * 0.3 +
            carbsScore    * 0.2 +
            fatScore      * 0.1
        
        return Int(totalScore.rounded())
    }

    /// Score for how well timed are your meals
    func timingAdherenceScore(
          targets: Macros,
          pre: Macros,
          post: Macros
      ) -> Int {
          let targetCarbs = targets.carbs
          let targetProtein = targets.protein
          
          // If targets are missing or tiny, timing doesn't matter much.
          guard targetCarbs > 0, targetProtein > 0 else {
              return 100
          }
          
          // Very simple "ideal" distribution for training days:
          // - Pre: 30% of carbs, 20% of protein
          // - Post: 30% of carbs, 30% of protein
          let idealPreCarbs = targetCarbs * 0.30
          let idealPreProtein = targetProtein * 0.20
          
          let idealPostCarbs = targetCarbs * 0.30
          let idealPostProtein = targetProtein * 0.30
          
          // More forgiving tolerance for carbs timing than total macros.
          let preCarbScore = ratioScore(
              actual: pre.carbs,
              target: idealPreCarbs,
              tolerance: 0.5
          )
          let preProteinScore = ratioScore(
              actual: pre.protein,
              target: idealPreProtein,
              tolerance: 0.5
          )
          
          let postCarbScore = ratioScore(
              actual: post.carbs,
              target: idealPostCarbs,
              tolerance: 0.5
          )
          let postProteinScore = ratioScore(
              actual: post.protein,
              target: idealPostProtein,
              tolerance: 0.5
          )
          
          // Pre window: carbs are slightly more important than protein.
          let preScore = preCarbScore * 0.6 + preProteinScore * 0.4
          
          // Post window: carbs & protein are equally important.
          let postScore = postCarbScore * 0.5 + postProteinScore * 0.5
          
          let timingScore = (preScore + postScore) / 2.0
          
          return Int(timingScore.rounded())
      }
    
    // computed fuel score
    func computeFuelScore(for dayLog: DayLog) -> FuelScore? {
          let targets = dayLog.macroTargets
          
          // Do not bother scoring if calorie target is absurdly low.
          guard targets.calories >= 800 else {
              return nil
          }
          
          let consumed = consumedMacros
          let macroScore = macroAdherenceScore(
              targets: targets,
              consumed: consumed
          )
          
          // If there's no training session, timing = macros.
          guard dayLog.isTrainingDay, dayLog.sessionStart != nil else {
              return FuelScore(
                  total: macroScore,
                  macroAdherence: macroScore,
                  timingAdherence: macroScore
              )
          }
          
          // Training day with a session → timing matters.
          let pre = preWorkoutMacros
          let post = postWorkoutMacros
          
          let timingScore = timingAdherenceScore(
              targets: targets,
              pre: pre,
              post: post
          )
          
          let intensity = dayLog.trainingIntensity ?? .normal
          
          // Harder days → timing matters more.
          let timingWeight: Double
          switch intensity {
          case .recovery:
              timingWeight = 0.3
          case .normal:
              timingWeight = 0.4
          case .hard:
              timingWeight = 0.5
          case .allOut:
              timingWeight = 0.6
          }
          
          let macroWeight = 1.0 - timingWeight
          
          let totalScore =
              Double(macroScore) * macroWeight +
              Double(timingScore) * timingWeight
          
          return FuelScore(
              total: Int(totalScore.rounded()),
              macroAdherence: macroScore,
              timingAdherence: timingScore
          )
      }
    
    func refreshFuelScore() {
        guard var current = dayLog else { return }
        
        if let score = computeFuelScore(for: current) {
            current.fuelScore = score
        } else {
            current.fuelScore = nil
        }
        
        self.dayLog = current
    }
}
