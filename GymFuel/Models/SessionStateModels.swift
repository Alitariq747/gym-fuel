//
//  SessionStateModels.swift
//  GymFuel
//
//  Created for modular training-state system.
//

import Foundation

/// Top-level day mode used by the UI state engine.
enum DayMode: Equatable {
    case rest
    case training(TrainingPhase)
}

/// Time-driven training phases.
enum TrainingPhase: String, CaseIterable, Equatable {
    case scheduled
    case preWorkout
    case inWorkout
    case postWorkout
    case support
}

enum ScheduledSubstate: String, CaseIterable, Equatable {
    case onTarget
    case underFueled
    case overFueled
}

enum PreWorkoutSubstate: String, CaseIterable, Equatable {
    case needPreMeal
    case lowCarbPre
    case heavy
    case onTarget
}


enum InWorkoutSubstate: String, CaseIterable, Equatable {
    case hydratedAndFueled
}


enum PostWorkoutSubstate: String, CaseIterable, Equatable {
    case needRecoveryMeal
    case lowProteinRecovery
    case lowCarbRecovery
    case recoveryOnTrack
}


enum SupportSubstate: String, CaseIterable, Equatable {
    case underFueled
    case onTarget
    case overFueled
}


enum TrainingSubstate: Equatable {
    case scheduled(ScheduledSubstate)
    case preWorkout(PreWorkoutSubstate)
    case inWorkout(InWorkoutSubstate)
    case postWorkout(PostWorkoutSubstate)
    case support(SupportSubstate)
}


enum SessionTone: String, Equatable {
    case calm
    case focused
    case assertive
    case recovery
}

/// UI copy payload derived from (phase + substate + tone).
struct SessionStateContent: Equatable {
    let title: String
    let message: String
    let nextRecommendation: String
    let tone: SessionTone
}

/// Final state object intended for UI consumption.
struct ResolvedSessionState: Equatable {
    let dayMode: DayMode
    let substate: TrainingSubstate?
    let content: SessionStateContent
}
