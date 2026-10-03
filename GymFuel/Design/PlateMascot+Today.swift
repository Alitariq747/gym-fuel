//
//  PlateMascot+Today.swift
//  GymFuel
//
//  Shared with the widget extension.
//

extension PlateMascot.Move {
    /// Mascot rule 9: the pose follows whether anything is logged, never how the
    /// day is going — so over target still writes.
    static func today(_ snapshot: TodaySnapshot?) -> Self {
        guard let snapshot else { return .phone }
        return snapshot.loggedCount == 0 ? .wave : .write
    }
}
