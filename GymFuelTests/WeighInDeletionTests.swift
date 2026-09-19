//
//  WeighInDeletionTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import LiftEats

@Suite("WeighInDeletion")
struct WeighInDeletionTests {
    /// `day` is a 1-based offset into September 2026, so the keys sort naturally.
    private func weighIn(day: Int, _ weightKg: Double, _ source: WeighInSource = .manual) -> WeighIn {
        WeighIn(
            dateKey: String(format: "2026-09-%02d", day),
            weightKg: weightKg,
            loggedAt: Date(timeIntervalSince1970: 0),
            source: source
        )
    }

    // MARK: - What can be deleted

    @Test("A typed weigh-in can be deleted while others remain")
    func typedIsDeletable() {
        let typed = weighIn(day: 3, 84)

        #expect(WeighInDeletion.canDelete(typed, among: [weighIn(day: 1, 85), typed]))
    }

    @Test("An Apple Health weigh-in can't be deleted")
    func healthIsNot() {
        let health = weighIn(day: 3, 84, .healthKit)

        #expect(!WeighInDeletion.canDelete(health, among: [weighIn(day: 1, 85), health]))
    }

    @Test("The only weigh-in on screen can't be deleted")
    func onlyOneIsNot() {
        let only = weighIn(day: 3, 84)

        #expect(!WeighInDeletion.canDelete(only, among: [only]))
    }

    // MARK: - The weight shown afterwards

    @Test("Deleting the newest moves the weight back to the one before it")
    func newestMovesBack() {
        let newest = weighIn(day: 5, 83.6)
        let weighIns = [weighIn(day: 1, 85), weighIn(day: 3, 84.2, .healthKit), newest]

        #expect(WeighInDeletion.profileWeight(afterDeleting: newest, among: weighIns) == 84.2)
    }

    @Test("Deleting an older weigh-in leaves the weight alone")
    func olderLeavesWeight() {
        let older = weighIn(day: 1, 85)
        let weighIns = [older, weighIn(day: 3, 84.2), weighIn(day: 5, 83.6)]

        #expect(WeighInDeletion.profileWeight(afterDeleting: older, among: weighIns) == nil)
    }

    @Test("The list's order doesn't matter")
    func orderDoesNotMatter() {
        let newest = weighIn(day: 5, 83.6)
        let weighIns = [newest, weighIn(day: 1, 85), weighIn(day: 3, 84.2)]

        #expect(WeighInDeletion.profileWeight(afterDeleting: newest, among: weighIns) == 84.2)
    }
}
