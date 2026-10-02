//
//  AppConfig.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 10/06/2026.
//

import Foundation

enum AppConfig {
    static var backendBaseURL: URL {
        
        let value = (Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard
            let url = URL(string: value),
            ["http", "https"].contains(url.scheme?.lowercased()),
            url.host != nil
        else {
            fatalError("Missing or invalid BACKEND_BASE_URL")
        }

        return url
    }

    static let privacyPolicyURL = URL(string: "https://ahmadtariq.co/apps/circa/privacy")!
    static let termsURL = URL(string: "https://ahmadtariq.co/apps/circa/terms")!
    static let supportEmailURL = URL(string: "mailto:support-circa@ahmadtariq.co")!
}
