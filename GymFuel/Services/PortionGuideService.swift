//
//  PortionGuideService.swift
//  GymFuel
//

import Foundation
import FirebaseAppCheck

protocol PortionGuideService: Sendable {
    /// The raw payload, so the store can save exactly what the server sent.
    func fetchGuideData() async throws -> Data
}

struct BackendPortionGuideService: PortionGuideService {
    var baseURL: URL = AppConfig.backendBaseURL

    func fetchGuideData() async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent("portionGuide"))
        let appCheckToken = try await AppCheck.appCheck().token(forcingRefresh: false).token
        request.setValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
