//
//  SessionStateContext.swift
//  GymFuel
//
//  Input contract for resolving training/rest session UI state.
//

import Foundation


struct SessionStateContext: Equatable {
   
    let dayLog: DayLog

   
    let now: Date

   
    let consumedMacros: Macros

    /// Optional phase-specific macro snapshots.
    let preWorkoutConsumedMacros: Macros
    let postWorkoutConsumedMacros: Macros
    let supportConsumedMacros: Macros

  
    let preWorkoutLeadMinutes: Int

  
    let supportLagMinutes: Int

    init(
        dayLog: DayLog,
        now: Date,
        consumedMacros: Macros,
        preWorkoutConsumedMacros: Macros = .zero,
        postWorkoutConsumedMacros: Macros = .zero,
        supportConsumedMacros: Macros = .zero,
        preWorkoutLeadMinutes: Int = 90,
        supportLagMinutes: Int = 180
    ) {
        self.dayLog = dayLog
        self.now = now
        self.consumedMacros = consumedMacros
        self.preWorkoutConsumedMacros = preWorkoutConsumedMacros
        self.postWorkoutConsumedMacros = postWorkoutConsumedMacros
        self.supportConsumedMacros = supportConsumedMacros
        self.preWorkoutLeadMinutes = preWorkoutLeadMinutes
        self.supportLagMinutes = supportLagMinutes
    }
}

extension SessionStateContext {
    var targets: Macros {
        dayLog.macroTargets
    }

    var sessionStart: Date? {
        dayLog.sessionStart
    }

    var sessionDurationMinutes: Int {
        dayLog.sessionDurationMinutes ?? 60
    }

    var sessionEnd: Date? {
        guard let sessionStart else { return nil }
        return Calendar.current.date(
            byAdding: .minute,
            value: sessionDurationMinutes,
            to: sessionStart
        )
    }

    var isTrainingDay: Bool {
        dayLog.isTrainingDay
    }

    var intensity: TrainingIntensity? {
        dayLog.trainingIntensity
    }

    var sessionType: SessionType? {
        dayLog.sessionType
    }

    var calorieProgress: Double {
        progress(consumed: consumedMacros.calories, target: targets.calories)
    }

    var proteinProgress: Double {
        progress(consumed: consumedMacros.protein, target: targets.protein)
    }

    var carbProgress: Double {
        progress(consumed: consumedMacros.carbs, target: targets.carbs)
    }

    var fatProgress: Double {
        progress(consumed: consumedMacros.fat, target: targets.fat)
    }

    private func progress(consumed: Double, target: Double) -> Double {
        guard target > 0 else { return 0 }
        return consumed / target
    }
}
