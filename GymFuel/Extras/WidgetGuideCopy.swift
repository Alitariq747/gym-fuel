//
//  WidgetGuideCopy.swift
//  GymFuel
//

import Foundation

/// The onboarding widget step's instructions. Markdown bold marks what the
/// person taps.
enum WidgetGuideCopy {

    enum Place: CaseIterable {
        case homeScreen, lockScreen

        var title: String {
            switch self {
            case .homeScreen: "Home Screen"
            case .lockScreen: "Lock Screen"
            }
        }
    }

    /// iOS 18 moved Add Widget behind the Home Screen's Edit button; iOS 17 has a +.
    static func steps(for place: Place, hasEditButton: Bool) -> [String] {
        switch place {
        case .homeScreen:
            [
                "Hold an empty spot on your Home Screen.",
                hasEditButton ? "Tap **Edit**, then **Add Widget**." : "Tap **+** in the top corner.",
                "Search for **Circa** and pick a size.",
                "Tap **Add Widget**, then **Done**."
            ]
        case .lockScreen:
            [
                "Hold your Lock Screen, tap **Customize**.",
                "Tap the **Lock Screen** preview.",
                "Tap the space under the time.",
                "Tap **Circa**, pick a widget, then **Done**."
            ]
        }
    }
}
