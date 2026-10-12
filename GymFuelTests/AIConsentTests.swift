//
//  AIConsentTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import Circa

@Suite("When a meal may be sent to the AI provider")
struct AIConsentTests {

    @Test("Never asked is not consent")
    func neverAskedIsNotConsent() {
        #expect(!AIConsent.isGranted(storedVersion: 0))
    }

    @Test("Agreeing to the current version is")
    func currentVersionIsConsent() {
        #expect(AIConsent.isGranted(storedVersion: AIConsent.version))
    }

    @Test("Agreeing to an earlier version asks again")
    func earlierVersionAsksAgain() {
        #expect(!AIConsent.isGranted(storedVersion: AIConsent.version - 1))
    }
}
