//
//  LoggingProblemTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("LoggingProblem")
struct LoggingProblemTests {
    private let all = LoggingProblem.allCases

    @Test("The four answers come in the order the question lists them")
    func order() {
        #expect(all == [.notInDatabase, .unknownPortions, .tooSlow, .neverTracked])
    }

    /// "Every answer changes something later, or the question goes."
    @Test("Each answer has its own try-meal line, unlike the line with no answer")
    func tryMealLinesDiffer() {
        let lines = all.map(\.tryMealDetail)
        #expect(Set(lines).count == all.count)
        #expect(!lines.contains(LoggingProblem.defaultTryMealDetail))
    }

    @Test("Each answer has its own plan-screen line")
    func planLinesDiffer() {
        #expect(Set(all.map(\.planLine)).count == all.count)
    }

    @Test("Each answer has its own paywall subtitle")
    func paywallSubtitlesDiffer() {
        #expect(Set(all.map(\.paywallSubtitle)).count == all.count)
    }

    @Test("Raw values work as analytics names")
    func analyticsNames() {
        for problem in all {
            #expect(problem.rawValue.allSatisfy { $0.isLowercase || $0 == "_" }, "\(problem)")
        }
    }

    /// Step 15's rules: no invented numbers, and nothing calls anything a burn.
    @Test("No line has a number or the word burn")
    func noNumbersOrBurn() {
        let copy = all.flatMap { [$0.title, $0.tryMealDetail, $0.planLine, $0.paywallSubtitle] }.joined(separator: " ")
        #expect(!copy.contains { $0.isNumber })
        #expect(!copy.lowercased().contains("burn"))
    }
}
