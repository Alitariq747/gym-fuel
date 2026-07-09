import Foundation
import FirebaseAuth
import FirebaseAppCheck

enum BackendSubscriptionSyncError: LocalizedError {
    case unauthorized
    case appCheckFailed
    case serverUnavailable
    case invalidResponse
    case networkUnavailable
    case requestTimedOut
    case syncFailed(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please sign in again and try restoring your subscription."
        case .appCheckFailed:
            return "We couldn't verify this app session. Please try again."
        case .serverUnavailable:
            return "Subscription restored, but we couldn't sync access yet. Please try Restore again."
        case .invalidResponse:
            return "Subscription restored, but we couldn't sync access yet. Please try Restore again."
        case .networkUnavailable:
            return "You're offline or the connection is unstable. Please try again."
        case .requestTimedOut:
            return "The subscription sync took too long. Please try again."
        case .syncFailed(let message):
            return message
        case .unknown:
            return "Subscription restored, but we couldn't sync access yet. Please try Restore again."
        }
    }
}

final class BackendSubscriptionService: @unchecked Sendable {
    static let shared = BackendSubscriptionService()

    private let baseURL: URL

    private init(baseURL: URL = AppConfig.backendBaseURL) {
        self.baseURL = baseURL
    }

    private struct BackendErrorResponse: Codable {
        var error: String
        var message: String?
    }

    private struct SubscriptionSyncResponse: Codable {
        var plan: String
        var entitlementActive: Bool
        var productId: String?
    }

    func syncSubscription() async throws {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("subscription")
            .appendingPathComponent("sync")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data()

        let idToken = try await Auth.auth().currentUser?.getIDToken() ?? ""
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let appCheckToken = try await AppCheck.appCheck().token(forcingRefresh: false).token
        request.setValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            throw mapTransportError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendSubscriptionSyncError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw mapBackendErrorResponse(data, statusCode: httpResponse.statusCode)
        }

        guard let decoded = try? JSONDecoder().decode(SubscriptionSyncResponse.self, from: data),
              decoded.entitlementActive,
              decoded.plan == "pro" else {
            throw BackendSubscriptionSyncError.invalidResponse
        }
    }

    private func mapTransportError(_ error: URLError) -> BackendSubscriptionSyncError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return .networkUnavailable
        case .timedOut:
            return .requestTimedOut
        default:
            return .unknown
        }
    }

    private func mapBackendErrorResponse(_ data: Data, statusCode: Int) -> BackendSubscriptionSyncError {
        if let backendError = try? JSONDecoder().decode(BackendErrorResponse.self, from: data),
           backendError.error == "subscription/sync-failed" {
            return .syncFailed(
                backendError.message ?? "Subscription restored, but we couldn't sync access yet. Please try Restore again."
            )
        }

        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .appCheckFailed
        case 504:
            return .requestTimedOut
        case 429, 500...599:
            return .serverUnavailable
        default:
            return .invalidResponse
        }
    }
}
