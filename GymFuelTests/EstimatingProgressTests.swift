//
//  EstimatingProgressTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import Circa

@Suite("Estimating progress")
struct EstimatingProgressTests {

    private func percent(_ seconds: TimeInterval) -> Double {
        EstimatingProgress.fraction(elapsed: seconds) * 100
    }

    @Test func startsEmpty() {
        #expect(percent(0) == 0)
        #expect(percent(-3) == 0)
    }

    @Test func fastThenSlower() {
        #expect(abs(percent(6) - 60) < 1)
        #expect(abs(percent(14) - 86) < 1)
        #expect(abs(percent(25) - 94) < 1)
        #expect(percent(6) - percent(3) > percent(20) - percent(17))
    }

    /// Only a landed estimate shows 100%, however long the wait.
    @Test func neverFullWhileWaiting() {
        #expect(percent(120) < 95.01)
        #expect(percent(120) > percent(60))
    }
}
