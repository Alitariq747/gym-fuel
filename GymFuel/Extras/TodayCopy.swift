//
//  TodayCopy.swift
//  GymFuel
//
//  Shared with the widget extension.
//

import Foundation

/// What the widget says about today, in the Day card's words.
enum TodayCopy {
    static let emptyTitle = "Your day shows here"
    static let emptyAction = "Open the app"
    static let emptyActionWide = "Open the app to see what's left of today."

    static func number(_ snapshot: TodaySnapshot) -> String {
        abs(snapshot.caloriesLeft).formatted()
    }

    /// Inside the Lock Screen's circle, where "kcal" does not fit.
    static func shortLabel(_ snapshot: TodaySnapshot) -> String {
        snapshot.caloriesLeft < 0 ? "over" : "left"
    }

    static func label(_ snapshot: TodaySnapshot) -> String {
        "kcal \(shortLabel(snapshot))"
    }

    /// The `Empty day` artboard: nothing eaten reads as the whole day ahead, not a zero.
    static func progress(_ snapshot: TodaySnapshot) -> String {
        let eaten = Int(snapshot.eaten.calories.rounded())
        guard eaten != 0 else { return "the whole day" }
        return "\(eaten.formatted()) of \(Int(snapshot.target.calories.rounded()).formatted())"
    }

    /// VoiceOver: the Day card's sentence, with the dotted rule said aloud.
    static func spoken(_ snapshot: TodaySnapshot) -> String {
        "\(number(snapshot)) calories \(shortLabel(snapshot))\(snapshot.hasEstimate ? ", estimated" : ""), \(progress(snapshot))"
    }

    static func inline(_ snapshot: TodaySnapshot?) -> String {
        guard let snapshot else { return "Open to see today" }
        return "\(number(snapshot)) \(label(snapshot))"
    }
}
