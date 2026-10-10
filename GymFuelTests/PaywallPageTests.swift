//
//  PaywallPageTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("PaywallPage")
struct PaywallPageTests {
    @Test("With a trial, every page shows in order")
    func sequenceWithTrial() {
        #expect(PaywallPage.sequence(hasTrial: true) == [.features, .trial, .plans])
    }

    @Test("Without a trial, the trial page is skipped")
    func sequenceWithoutTrial() {
        #expect(PaywallPage.sequence(hasTrial: false) == [.features, .plans])
    }

    @Test("Continue walks forward through the trial page")
    func nextWithTrial() {
        #expect(PaywallPage.features.next(hasTrial: true) == .trial)
        #expect(PaywallPage.trial.next(hasTrial: true) == .plans)
        #expect(PaywallPage.plans.next(hasTrial: true) == nil)
    }

    @Test("Continue goes straight to the plans without a trial")
    func nextWithoutTrial() {
        #expect(PaywallPage.features.next(hasTrial: false) == .plans)
        #expect(PaywallPage.plans.next(hasTrial: false) == nil)
    }

    @Test("Back retraces the same pages")
    func previous() {
        #expect(PaywallPage.plans.previous(hasTrial: true) == .trial)
        #expect(PaywallPage.trial.previous(hasTrial: true) == .features)
        #expect(PaywallPage.plans.previous(hasTrial: false) == .features)
        #expect(PaywallPage.features.previous(hasTrial: true) == nil)
        #expect(PaywallPage.features.previous(hasTrial: false) == nil)
    }
}
