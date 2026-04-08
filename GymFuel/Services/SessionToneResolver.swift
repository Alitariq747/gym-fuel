//
//  SessionToneResolver.swift
//  GymFuel
//
//  Resolves communication tone from session context.
//

import Foundation

struct SessionToneResolver {
    func resolveTone(context: SessionStateContext) -> SessionTone {
        guard context.isTrainingDay else {
            return .calm
        }

        let intensityTone = toneForIntensity(context.intensity)
        return adjustedTone(base: intensityTone, sessionType: context.sessionType)
    }
}

private extension SessionToneResolver {
    func toneForIntensity(_ intensity: TrainingIntensity?) -> SessionTone {
        switch intensity ?? .normal {
        case .recovery:
            return .recovery
        case .normal:
            return .focused
        case .hard, .allOut:
            return .assertive
        }
    }

    func adjustedTone(base: SessionTone, sessionType: SessionType?) -> SessionTone {
        guard let sessionType else { return base }

        switch sessionType {
        case .mobility:
            return .recovery
        case .cardio:
            return base == .assertive ? .focused : base
        case .conditioning, .sports:
            return base == .calm ? .focused : base
        case .push, .pull, .legs, .upper, .lower, .fullBody:
            return base
        }
    }
}
