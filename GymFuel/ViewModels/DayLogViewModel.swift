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
    @Published private(set) var currentDayMode: DayMode = .rest
    @Published private(set) var currentTrainingSubstate: TrainingSubstate?
    @Published private(set) var currentSessionTone: SessionTone = .calm
    @Published private(set) var currentSessionContent = SessionStateContent(
        title: "Recovery Day",
        message: "Keep intake steady and focus on consistency.",
        nextRecommendation: "Hit your daily protein target and hydrate.",
        tone: .calm
    )

    private var loadTask: Task<Void, Never>?
    private var activeLoadId: UUID?
    private var phaseClockTask: Task<Void, Never>?

    // Dependencies
    private let planner: MacrosPlanner
    private let phaseResolver = TrainingPhaseResolver()
    private let substateResolver = TrainingSubstateResolver()
    private let toneResolver = SessionToneResolver()
    private let contentProvider = SessionStateContentProvider()
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
                    recomputeDayMode()
                    
                    // 1b)
                    do {
                        let loadedMeals = try await mealService.fetchMeals(for: userId, dayLogId: existing.id)
                        guard isCurrentLoad(loadId) else { return }
                        self.meals = loadedMeals
                        
                        // Keep consumed macros in sync when meals load.
                        refreshConsumedMacros()

                        guard let updatedLog = self.dayLog else { return }
                        let shouldSave =
                            updatedLog.date != originalLog.date
                            || updatedLog.macroTargets != originalLog.macroTargets
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
                macroTargets: .zero
            )
            
            do {
                let macros = try planner.planDailyMacros(profile: profile, dayLog: newDayLog)
                newDayLog.macroTargets = macros
                self.dayLog = newDayLog
                recomputeDayMode()
                
                
                do {
                    let loadedMeals = try await mealService.fetchMeals(
                        for: userId,
                        dayLogId: newDayLog.id
                    )
                    guard isCurrentLoad(loadId) else { return }
                    self.meals = loadedMeals
                    
                    // Keep consumed macros in sync when meals load.
                    refreshConsumedMacros()

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
            current.sessionDurationMinutes = nil
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

    func setSessionDurationMinutes(_ sessionDurationMinutes: Int?) {
        guard var current = dayLog else { return }
        current.sessionDurationMinutes = sessionDurationMinutes
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
        refreshConsumedMacros()
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
        refreshConsumedMacros()
        
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
        refreshConsumedMacros()
        
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
        refreshConsumedMacros()
        
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
        refreshConsumedMacros()
        
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
        refreshConsumedMacros()
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
    
    /// Total consumed macros from meals in the pre-workout window.
      var preWorkoutConsumedMacros: Macros {
          macros(for: preWorkoutMeals)
      }
      
      /// Total consumed macros from meals in the post-workout window.
      var postWorkoutConsumedMacros: Macros {
          macros(for: postWorkoutMeals)
      }
      
      /// Total consumed macros from support meals on a training day.
      var supportConsumedMacros: Macros {
          macros(for: otherTrainingDayMeals)
      }
      
      /// Total consumed macros from meals on a rest day.
      var restDayConsumedMacros: Macros {
          macros(for: restDayMeals)
      }
    
    func refreshConsumedMacros() {
        guard var current = dayLog else { return }
        current.consumedMacros = macros(for: meals)
        self.dayLog = current
        recomputeDayMode()
    }

    func recomputeDayMode(now: Date = Date()) {
        guard let dayLog else {
            currentDayMode = .rest
            currentTrainingSubstate = nil
            currentSessionTone = .calm
            currentSessionContent = contentProvider.resolveContent(
                dayMode: .rest,
                substate: nil,
                tone: .calm
            )
            return
        }

        let context = SessionStateContext(
            dayLog: dayLog,
            now: now,
            consumedMacros: consumedMacros,
            preWorkoutConsumedMacros: preWorkoutConsumedMacros,
            postWorkoutConsumedMacros: postWorkoutConsumedMacros,
            supportConsumedMacros: supportConsumedMacros
        )

        let dayMode = phaseResolver.resolveDayMode(context: context)
        currentDayMode = dayMode

        if case .training(let phase) = dayMode {
            currentTrainingSubstate = substateResolver.resolveSubstate(for: phase, context: context)
        } else {
            currentTrainingSubstate = nil
        }

        currentSessionTone = toneResolver.resolveTone(context: context)
        currentSessionContent = contentProvider.resolveContent(
            dayMode: dayMode,
            substate: currentTrainingSubstate,
            tone: currentSessionTone
        )
    }

    func startPhaseClock() {
        stopPhaseClock()
        recomputeDayMode()

        phaseClockTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                if Task.isCancelled { break }
                await MainActor.run {
                    self?.recomputeDayMode()
                }
            }
        }
    }

    func stopPhaseClock() {
        phaseClockTask?.cancel()
        phaseClockTask = nil
    }

}
