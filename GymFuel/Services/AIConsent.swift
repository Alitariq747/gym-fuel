//
//  AIConsent.swift
//  GymFuel
//

import Foundation

/// Permission to send a meal to a third-party AI, asked once per install before
/// the first estimate (App Store 5.1.2(i)).
enum AIConsent {
    static let provider = "OpenAI"
    /// Raise when the provider or what is sent changes, so everyone is asked again.
    static let version = 1
    static let preferenceKey = "aiConsentVersion"

    static func isGranted(storedVersion: Int) -> Bool {
        storedVersion >= version
    }
}
