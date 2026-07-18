import FirebaseAppCheck
import FirebaseAuth
import Foundation

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
            return "Please sign in again and try activating your subscription."
        case .appCheckFailed:
            return "We couldn't verify this app session. Please try again."
        case .serverUnavailable, .invalidResponse, .unknown:
            return "Purchase completed, but we couldn't activate access yet. Please try Restore Subscription."
        case .networkUnavailable:
            return "You're offline or the connection is unstable. Please try again."
        case .requestTimedOut:
            return "The subscription sync took too long. Please try again."
        case .syncFailed(let message):
            return message
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
        let error: String
        let message: String?
    }

    private struct SubscriptionSyncResponse: Codable {
        let plan: String
        let entitlementActive: Bool
        let productId: String?
    }

    func syncSubscription() async throws {
        let url = baseURL.appendingPathComponent("api/subscription/sync")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data()

        guard let currentUser = Auth.auth().currentUser else {
            throw BackendSubscriptionSyncError.unauthorized
        }

        let idToken = try await currentUser.getIDToken()
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        do {
            let appCheckToken = try await AppCheck.appCheck().token(forcingRefresh: false).token
            request.setValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
        } catch {
            throw BackendSubscriptionSyncError.appCheckFailed
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            throw mapTransportError(error)
        } catch {
            throw BackendSubscriptionSyncError.unknown
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendSubscriptionSyncError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw mapBackendError(data: data, statusCode: httpResponse.statusCode)
        }

        let decodedResponse: SubscriptionSyncResponse
        do {
            decodedResponse = try JSONDecoder().decode(SubscriptionSyncResponse.self, from: data)
        } catch {
            throw BackendSubscriptionSyncError.invalidResponse
        }

        guard decodedResponse.entitlementActive, decodedResponse.plan == "pro" else {
            throw BackendSubscriptionSyncError.invalidResponse
        }
    }

    private func mapTransportError(_ error: URLError) -> BackendSubscriptionSyncError {
        switch error.code {
        case .notConnectedToInternet,
             .networkConnectionLost,
             .cannotFindHost,
             .cannotConnectToHost,
             .dnsLookupFailed:
            return .networkUnavailable
        case .timedOut:
            return .requestTimedOut
        default:
            return .unknown
        }
    }

    private func mapBackendError(data: Data, statusCode: Int) -> BackendSubscriptionSyncError {
        let backendError = try? JSONDecoder().decode(BackendErrorResponse.self, from: data)

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
            if let message = backendError?.message, message.isEmpty == false {
                return .syncFailed(message)
            }
            return .invalidResponse
        }
    }
}
