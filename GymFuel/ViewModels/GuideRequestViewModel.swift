//
//  GuideRequestViewModel.swift
//  GymFuel
//

import Foundation

@MainActor
final class GuideRequestViewModel: ObservableObject {
    enum Status: Equatable {
        case idle, sending, sent, failed
    }

    static let maxLength = 80

    @Published var text = "" {
        didSet {
            if text.count > Self.maxLength { text = String(text.prefix(Self.maxLength)) }
            if status != .sending { status = .idle }
        }
    }
    @Published private(set) var status: Status = .idle

    private let service: GuideRequestService
    private let networkMonitor: NetworkMonitoring

    init(
        service: GuideRequestService = FirebaseGuideRequestService(),
        networkMonitor: NetworkMonitoring = NetworkMonitor.shared
    ) {
        self.service = service
        self.networkMonitor = networkMonitor
    }

    /// Nil when there is nothing to send.
    static func cleaned(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var canSend: Bool {
        status != .sending && Self.cleaned(text) != nil
    }

    /// A failure keeps the words, so trying again costs nothing (design.md rule 6).
    func send(userId: String) async {
        guard canSend, let food = Self.cleaned(text) else { return }
        // Offline, Firestore would hold the write and never answer.
        guard networkMonitor.isConnected else {
            status = .failed
            return
        }
        status = .sending
        do {
            try await service.sendRequest(food: food, userId: userId)
            text = ""
            status = .sent
            FirebaseTelemetryService.logPortionGuideEvent("request_sent")
        } catch {
            status = .failed
        }
    }
}
