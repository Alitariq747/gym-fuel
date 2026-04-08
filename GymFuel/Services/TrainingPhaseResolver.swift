//
//  TrainingPhaseResolver.swift
//  GymFuel
//
//  Pure time-based resolver for training phases.
//

import Foundation

struct TrainingPhaseResolver {
   
    func resolveDayMode(context: SessionStateContext) -> DayMode {
        guard context.isTrainingDay else {
            return .rest
        }

        return .training(resolveTrainingPhase(context: context))
    }

    /// Resolves only the training phase using time windows.
    ///
    /// Window rules:
    /// - `scheduled`: before pre-workout window start
    /// - `preWorkout`: pre-window start ..< session start
    /// - `inWorkout`: session start ..< session end
    /// - `postWorkout`: session end ..< support start
    /// - `support`: support start and later
    func resolveTrainingPhase(context: SessionStateContext) -> TrainingPhase {
        guard let sessionStart = context.sessionStart,
              let sessionEnd = context.sessionEnd else {
        
            return .scheduled
        }

        let calendar = Calendar.current
        let preWorkoutStart = calendar.date(
            byAdding: .minute,
            value: -context.preWorkoutLeadMinutes,
            to: sessionStart
        ) ?? sessionStart

        let supportStart = calendar.date(
            byAdding: .minute,
            value: context.supportLagMinutes,
            to: sessionEnd
        ) ?? sessionEnd

        let now = context.now

        if now < preWorkoutStart {
            return .scheduled
        }

        if now < sessionStart {
            return .preWorkout
        }

        if now < sessionEnd {
            return .inWorkout
        }

        if now < supportStart {
            return .postWorkout
        }

        return .support
    }
}
