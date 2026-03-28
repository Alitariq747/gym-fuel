//
//  DayLogViewModel.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 11/12/2025.
//

import Foundation

@MainActor
final class DayLogViewModel: ObservableObject {
    
    @Published private(set) var dayLog: DayLog?
    
    @Published private(set) var meals: [Meal] = [] 
    
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isSavingMeal: Bool = false

    private var loadTask: Task<Void, Never>?
    private var activeLoadId: UUID?

    // Dependencies
    private let planner: MacrosPlanner
    private var profile: UserProfile
    private let dayLogService: DayLogService
    private let mealService: MealService
    
    init(profile: UserProfile, planner: MacrosPlanner = MacrosPlanner(), dayLogService: DayLogService = FirebaseDayLogService(), mealService: MealService = FirebaseMealService()) {
        self.profile = profile
        self.planner = planner
        self.dayLogService = dayLogService
        self.mealService = mealService
    }
    var userProfile: UserProfile {
        profile
    }
    
    func updateProfile(_ newProfile: UserProfile) {
        self.profile = newProfile
        
        if var current = self.dayLog {
            recalculateTargets(for: &current)
            self.dayLog = current
        }
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
    
    // Helpers for setting isTrainingDay
    private func stableSeed(from s: String) -> Int {
        // Deterministic across app launches (unlike Swift's hashValue).
        var result = 0
        for u in s.unicodeScalars {
            result = (result &* 31 &+ Int(u.value)) & 0x7fffffff
        }
        return result
    }

    private func defaultIsTrainingDay(for date: Date) -> Bool {
       
        let trainingDaysPerWeek = profile.trainingDaysPerWeek ?? 3
        let n = max(0, min(7, trainingDaysPerWeek ))

        if n == 0 { return false }
        if n == 7 { return true }

        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        let weekdayIndex = (weekday + 5) % 7

  
        let trainingWeekdays: Set<Int>
        switch n {
        case 1:
            trainingWeekdays = [2] // Wed
        case 2:
            trainingWeekdays = [1, 3] // Tue, Thu
        case 3:
            trainingWeekdays = [0, 2, 4] // Mon, Wed, Fri
        case 4:
            trainingWeekdays = [0, 1, 3, 4] // Mon, Tue, Thu, Fri
        case 5:
            trainingWeekdays = [0, 1, 2, 3, 4] // Mon-Fri
        case 6:
            trainingWeekdays = [0, 1, 2, 3, 4, 5] // Mon-Sat
        default:
            trainingWeekdays = []
        }

        return trainingWeekdays.contains(weekdayIndex)
    }

    private func isCurrentLoad(_ loadId: UUID) -> Bool {
        activeLoadId == loadId && !Task.isCancelled
    }

    func loadDay(date: Date = Date()) {
        loadTask?.cancel()
        let loadId = UUID()
        activeLoadId = loadId
        loadTask = Task { [weak self] in
            await self?.createOrLoadTodayLog(date: date, loadId: loadId)
        }
    }
    
    func createOrLoadTodayLog(date: Date = Date(), loadId: UUID? = nil) async {
            let loadId = loadId ?? UUID()
            activeLoadId = loadId
            isLoading = true
            errorMessage = nil

            defer {
                if isCurrentLoad(loadId) {
                    isLoading = false
                }
            }
            
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let userId = profile.id
            
            do {
                
                if var existing = try await dayLogService.fetchDayLog(for: userId, date: startOfDay) {
                    guard isCurrentLoad(loadId) else { return }
                    let originalLog = existing
                    // Ensure date is normalized
                    existing.date = startOfDay
                    
                 
                    let macros = try planner.planDailyMacros(profile: profile, dayLog: existing)
                    existing.macroTargets = macros
                    self.dayLog = existing
                    
                    // 1b)
                    do {
                        let loadedMeals = try await mealService.fetchMeals(for: userId, dayLogId: existing.id)
                        guard isCurrentLoad(loadId) else { return }
                        self.meals = loadedMeals
                        
                        // Recompute fuel score only when meals load successfully.
                        refreshFuelScore()

                        guard let updatedLog = self.dayLog else { return }
                        let shouldSave =
                            updatedLog.date != originalLog.date
                            || updatedLog.macroTargets != originalLog.macroTargets
                            || updatedLog.fuelScore != originalLog.fuelScore
                            || updatedLog.consumedMacros != originalLog.consumedMacros

                        if shouldSave {
                            try await dayLogService.saveDayLog(updatedLog)
                        }
                    } catch {
                        guard isCurrentLoad(loadId) else { return }
                        self.meals = []
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    
                    return
                }
            } catch {
                guard isCurrentLoad(loadId) else { return }
                // If fetch fails (e.g. permission issue), record the error
                // but still attempt to create a local DayLog below.
                if !(error is CancellationError) {
                    self.errorMessage = error.localizedDescription
                }
            }
            guard isCurrentLoad(loadId) else { return }
            
            // 2) No DayLog exists for today (or fetch failed) → create a new one locally.
            let newId = Self.dayId(for: startOfDay, userId: userId)

        
            let isTraining = defaultIsTrainingDay(for: startOfDay)
            let sessionStart = isTraining ? defaultSessionStart(for: startOfDay) : nil
            let intensity: TrainingIntensity? = isTraining ? .normal : nil
            
            var newDayLog = DayLog(
                id: newId,
                userId: userId,
                date: startOfDay,
                isTrainingDay: isTraining,
                sessionStart: sessionStart,
                trainingIntensity: intensity,
                sessionType: nil,
                macroTargets: .zero,
                fuelScore: nil
            )
            
            do {
                let macros = try planner.planDailyMacros(profile: profile, dayLog: newDayLog)
                newDayLog.macroTargets = macros
                self.dayLog = newDayLog
                
                
                do {
                    let loadedMeals = try await mealService.fetchMeals(
                        for: userId,
                        dayLogId: newDayLog.id
                    )
                    guard isCurrentLoad(loadId) else { return }
                    self.meals = loadedMeals
                    
                    // Recompute fuel score only when meals load successfully.
                    refreshFuelScore()

                    if let updatedLog = self.dayLog {
                        // Persist to Firestore (or queue offline).
                        try await dayLogService.saveDayLog(updatedLog)
                    }
                } catch {
                    guard isCurrentLoad(loadId) else { return }
                    self.meals = []
                    self.errorMessage = error.localizedDescription
                    return
                }
            } catch {
                guard isCurrentLoad(loadId) else { return }
                if !(error is CancellationError) {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    
    // to call save when changing session / training data
    func saveCurrentDayLog() async {
        guard let log = dayLog else { return }
        do {
            try await dayLogService.saveDayLog(log)
        } catch {
            errorMessage = error.localizedDescription
        }
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
           formatter.locale = Locale(identifier: "en_US_POSIX")
           formatter.timeZone = TimeZone.current
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
    
  
    
    func addMeal(description: String, macros: Macros, loggedAt: Date = Date()) async {
        guard let currentDayLog = dayLog else {
            return
           
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
    
    func addMealAi(originalDescription: String, parsedMeal: ParsedMeal, loggedAt: Date = Date()) async {
        isSavingMeal = true
        defer {
            isSavingMeal = false
        }
        if dayLog == nil {
            await createOrLoadTodayLog(date: loggedAt)
        }
        guard let currentDayLog = dayLog else {
            errorMessage = "Could not load a log for today. Please try again later."
            return
        }
        
        let macros = Macros(calories: parsedMeal.calories,
                            protein: parsedMeal.protein,
                            carbs: parsedMeal.carbs,
                            fat: parsedMeal.fat)
        let newMeal = Meal(id: UUID().uuidString, userId: profile.id, dayLogId: currentDayLog.id, loggedAt: loggedAt, description: originalDescription, macros: macros, aiName: parsedMeal.name, aiConfidence: parsedMeal.confidence, aiWarnings: parsedMeal.warnings, aiNotes: parsedMeal.notes, aiAssumptions: parsedMeal.assumptions)
        meals.append(newMeal)
        refreshFuelScore()
        
        do {
            try await mealService.saveMeal(newMeal)
                if let updatedDayLog = dayLog {
                    try await dayLogService.saveDayLog(updatedDayLog)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateMeal(_ updated: Meal) async {
        guard let index = meals.firstIndex(where: { $0.id == updated.id}) else {
            return
        }
        meals[index] = updated
        refreshFuelScore()
        
        do {
            try await mealService.saveMeal(updated)
            
            if let updatedDayLog = dayLog {
                try await dayLogService.saveDayLog(updatedDayLog)
            }
        } catch {
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

   
    func timingAdherenceScore(
          targets: Macros,
          pre: Macros,
          post: Macros
      ) -> Int {
          let targetCarbs = targets.carbs
          let targetProtein = targets.protein

          guard targetCarbs > 0, targetProtein > 0 else {
              return 100
          }

          let trainingTime = profile.trainingTimeOfDay ?? .varies
          let split = timingSplit(for: trainingTime)

          let idealPreCarbs = targetCarbs * split.preCarb
          let idealPreProtein = targetProtein * split.preProtein

          let idealPostCarbs = targetCarbs * split.postCarb
          let idealPostProtein = targetProtein * split.postProtein

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

          let timingScore = preScore * split.preWeight + postScore * split.postWeight

          return Int(timingScore.rounded())
      }

    private struct TimingSplit {
        let preCarb: Double
        let preProtein: Double
        let postCarb: Double
        let postProtein: Double
        let preWeight: Double
        let postWeight: Double
    }

    private func timingSplit(for time: TrainingTimeOfDay) -> TimingSplit {
        switch time {
        case .morning:
            // Often fasted: shift emphasis to post.
            return TimingSplit(
                preCarb: 0.20,
                preProtein: 0.10,
                postCarb: 0.40,
                postProtein: 0.40,
                preWeight: 0.30,
                postWeight: 0.70
            )
        case .midday:
            return TimingSplit(
                preCarb: 0.30,
                preProtein: 0.20,
                postCarb: 0.30,
                postProtein: 0.30,
                preWeight: 0.50,
                postWeight: 0.50
            )
        case .evening:
            return TimingSplit(
                preCarb: 0.40,
                preProtein: 0.30,
                postCarb: 0.20,
                postProtein: 0.20,
                preWeight: 0.60,
                postWeight: 0.40
            )
        case .varies:
            return TimingSplit(
                preCarb: 0.30,
                preProtein: 0.20,
                postCarb: 0.30,
                postProtein: 0.30,
                preWeight: 0.50,
                postWeight: 0.50
            )
        }
    }
    
    // computed fuel score
    func computeFuelScore(for dayLog: DayLog, using meals: [Meal]) -> FuelScore? {
        let targets = dayLog.macroTargets
        
        guard targets.calories > 800 else {
            return nil
        }
        
        let consumed = macros(for: meals)
        let macroScore = macroAdherenceScore(targets: targets, consumed: consumed)
        
        guard dayLog.isTrainingDay, let sessionStart = dayLog.sessionStart else {
            return FuelScore(total: macroScore, macroAdherence: macroScore, timingAdherence: macroScore)
        }
        
        let isTrainingDay = dayLog.isTrainingDay
        
        let groupedByTiming = Dictionary(grouping: meals) { meal in
            meal.timingTag(relativeTo: sessionStart, isTrainingDay: isTrainingDay)
        }
        
        let preMeals = groupedByTiming[.preWorkout] ?? []
        let postMeals = groupedByTiming[.postWorkout] ?? []
        
        let pre = macros(for: preMeals)
        let post = macros(for: postMeals)
        
        let timingScore = timingAdherenceScore(targets: targets, pre: pre, post: post)
        
        let intensity = dayLog.trainingIntensity ?? .normal
        
        let timingWeight: Double
        switch intensity {
        case .normal:
            timingWeight = 0.4
        case .hard:
            timingWeight = 0.5
        case .allOut:
            timingWeight = 0.6
        case .recovery:
            timingWeight = 0.3
        }
        
        let macroWeight = 1 - timingWeight
        let totalScore = Double(macroScore) * macroWeight + Double(timingScore) * timingWeight
        return FuelScore(total: Int(totalScore.rounded()), macroAdherence: macroScore, timingAdherence: timingScore)
        
        
    }
    
 
    func computeFuelScore(for dayLog: DayLog) -> FuelScore? {
        return computeFuelScore(for: dayLog, using: meals)
    }

    struct MealFuelImpact {
        let totalDelta: Int
        let macroDelta: Int
        let timingDelta: Int
    }
    
    var fuelImpactByMealId: [String: MealFuelImpact] {
        guard let log = dayLog, !meals.isEmpty else { return [:] }
        
        // sort meals in time order using loggedAt
        let sortedMeals = meals.sorted { $0.loggedAt < $1.loggedAt }
        
        var result: [String: MealFuelImpact] = [:]
        
        // start with an empty score
        var previousScore: FuelScore? = computeFuelScore(for: log, using: [])
        
        // loop  through the meals for the day
        for (index, meal) in sortedMeals.enumerated() {
            let mealsUptoNow = Array(sortedMeals[0...index])
            
            let newScore = computeFuelScore(for: log, using: mealsUptoNow)
            
            let totalDelta: Int
            let macroDelta: Int
            let timingDelta: Int
            
            switch(previousScore, newScore) {
            case let (before?, after?):
                totalDelta  = after.total - before.total
                macroDelta  = after.macroAdherence - before.macroAdherence
                timingDelta = after.timingAdherence - before.timingAdherence
            
            case(nil, let after?):
                totalDelta = after.total
                macroDelta = after.macroAdherence
                timingDelta = after.timingAdherence
            default:
                totalDelta = 0
                macroDelta = 0
                timingDelta = 0
            }
            result[meal.id] = MealFuelImpact(totalDelta: totalDelta, macroDelta: macroDelta, timingDelta: timingDelta)
            previousScore = newScore
        }
        return result
    }
    
    func refreshFuelScore() {
        guard var current = dayLog else { return }
        
        let consumed = macros(for: meals)
        current.consumedMacros = consumed
        
        if let score = computeFuelScore(for: current, using: meals) {
            current.fuelScore = score
        } else {
            current.fuelScore = nil
        }
        
        self.dayLog = current
    }

}
