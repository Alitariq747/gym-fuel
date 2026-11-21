//
//  GuideRequestViewModelTests.swift
//  GymFuelTests
//

import Foundation
import Testing

@testable import Circa

@Suite("GuideRequestViewModel")
@MainActor
struct GuideRequestViewModelTests {
    private final class FakeService: GuideRequestService, @unchecked Sendable {
        var sent: [(food: String, userId: String)] = []
        var error: Error?

        func sendRequest(food: String, userId: String) async throws {
            if let error { throw error }
            sent.append((food, userId))
        }
    }

    private struct FakeNetwork: NetworkMonitoring {
        var isConnected: Bool
    }

    private func model(_ service: FakeService, online: Bool = true) -> GuideRequestViewModel {
        GuideRequestViewModel(service: service, networkMonitor: FakeNetwork(isConnected: online))
    }

    @Test func blankWordsCannotBeSent() {
        let model = model(FakeService())
        model.text = "  \n "
        #expect(GuideRequestViewModel.cleaned(model.text) == nil)
        #expect(!model.canSend)
    }

    @Test func wordsAreCappedAtEightyCharacters() {
        let model = model(FakeService())
        model.text = String(repeating: "a", count: 100)
        #expect(model.text.count == GuideRequestViewModel.maxLength)
    }

    @Test func aSentRequestIsTrimmedAndClearsTheBox() async {
        let service = FakeService()
        let model = model(service)
        model.text = "  sweet potato "
        await model.send(userId: "u1")
        #expect(service.sent.map(\.food) == ["sweet potato"])
        #expect(service.sent.map(\.userId) == ["u1"])
        #expect(model.text.isEmpty)
        #expect(model.status == .sent)
    }

    @Test func aFailureKeepsTheWords() async {
        let service = FakeService()
        service.error = URLError(.timedOut)
        let model = model(service)
        model.text = "sweet potato"
        await model.send(userId: "u1")
        #expect(model.text == "sweet potato")
        #expect(model.status == .failed)
    }

    @Test func offlineFailsWithoutWaitingOnFirestore() async {
        let service = FakeService()
        let model = model(service, online: false)
        model.text = "sweet potato"
        await model.send(userId: "u1")
        #expect(service.sent.isEmpty)
        #expect(model.status == .failed)
        #expect(model.text == "sweet potato")
    }

    @Test func typingAgainClearsTheLastResult() async {
        let model = model(FakeService())
        model.text = "sweet potato"
        await model.send(userId: "u1")
        model.text = "o"
        #expect(model.status == .idle)
    }
}
