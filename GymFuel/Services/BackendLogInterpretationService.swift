import Foundation
import FirebaseAuth
import FirebaseAppCheck

enum BackendLogInterpretationError: LocalizedError {
    case unauthorized
    case appCheckFailed
    case serverUnavailable
    case invalidResponse
    case decodingFailed
    case networkUnavailable
    case requestTimedOut
    case unknown

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please sign in again and try logging your meal."
        case .appCheckFailed:
            return "We couldn't verify this app session. Please try again."
        case .serverUnavailable:
            return "The meal analysis service is unavailable right now. Try again shortly."
        case .invalidResponse:
            return "We couldn't understand the server response. Please try again."
        case .decodingFailed:
            return "We couldn't process the meal analysis response. Please try again."
        case .networkUnavailable:
            return "You're offline or the connection is unstable. Please try again."
        case .requestTimedOut:
            return "The request took too long. Please try again."
        case .unknown:
            return "Something went wrong while logging your meal. Please try again."
        }
    }
}

final class BackendLogInterpretationService: LogInterpretationService, @unchecked Sendable {
    private let baseURL: URL

    init(baseURL: URL = URL(string: "https://greater-pill-vehicle-allows.trycloudflare.com")!) {
        self.baseURL = baseURL
    }

    private struct TextInterpretationRequest: Codable {
        var text: String
        var goal: GoalType
    }

    private struct MultipartFormDataBuilder {
        let boundary: String
        private(set) var body = Data()

        mutating func addTextField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        mutating func addFileField(name: String, filename: String, mimeType: String, data: Data) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }

        mutating func finalize() -> Data {
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            return body
        }
    }

    private struct TextInterpretationResponse: Codable {
        var type: LogEntryType
        var title: String
        var detail: String?
        var feedback: LogEntryFeedback
    }

    private func makeLogEntry(
        from response: TextInterpretationResponse,
        rawText: String,
        userId: String,
        loggedAt: Date
    ) -> LogEntry {
        LogEntry(
            userId: userId,
            loggedAt: loggedAt,
            type: response.type,
            title: response.title,
            rawInput: rawText,
            detail: response.detail,
            feedback: response.feedback
        )
    }

    private func makeRequestData(from request: TextInterpretationRequest) throws -> Data {
        try JSONEncoder().encode(request)
    }

    private func makeImageMultipartFormData(imageData: Data, goal: GoalType) -> (boundary: String, body: Data) {
        let boundary = "Boundary-\(UUID().uuidString)"
        var builder = MultipartFormDataBuilder(boundary: boundary)
        builder.addTextField(name: "goal", value: goal.rawValue)
        builder.addFileField(
            name: "image",
            filename: "meal.jpg",
            mimeType: "image/jpeg",
            data: imageData
        )
        return (boundary, builder.finalize())
    }

    private func mapTransportError(_ error: URLError) -> BackendLogInterpretationError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return .networkUnavailable
        case .timedOut:
            return .requestTimedOut
        default:
            return .unknown
        }
    }

    private func mapHTTPStatusCode(_ statusCode: Int) -> BackendLogInterpretationError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .appCheckFailed
        case 429, 500...599:
            return .serverUnavailable
        default:
            return .invalidResponse
        }
    }

    private func sendTextInterpretationRequest(_ requestData: Data) async throws -> TextInterpretationResponse {
        let url = baseURL.appendingPathComponent("interpretText")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData

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
            throw BackendLogInterpretationError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw mapHTTPStatusCode(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(TextInterpretationResponse.self, from: data)
        } catch {
            throw BackendLogInterpretationError.decodingFailed
        }
    }

    private func sendImageInterpretationRequest(imageData: Data, goal: GoalType) async throws -> TextInterpretationResponse {
        let url = baseURL.appendingPathComponent("interpretMealImage")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let multipartBody = makeImageMultipartFormData(imageData: imageData, goal: goal)
        request.setValue("multipart/form-data; boundary=\(multipartBody.boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = multipartBody.body

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
            throw BackendLogInterpretationError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw mapHTTPStatusCode(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(TextInterpretationResponse.self, from: data)
        } catch {
            throw BackendLogInterpretationError.decodingFailed
        }
    }


    func interpretText(
        _ text: String,
        userId: String,
        goal: GoalType,
        loggedAt: Date
    ) async throws -> LogEntry {
        let request = TextInterpretationRequest(text: text, goal: goal)
        let requestData = try makeRequestData(from: request) // encoding
        let response = try await sendTextInterpretationRequest(requestData)  // sending request
        return makeLogEntry(from: response, rawText: text, userId: userId, loggedAt: loggedAt)  
    }

    func interpretMealImage(
        _ imageData: Data,
        userId: String,
        goal: GoalType,
        loggedAt: Date
    ) async throws -> LogEntry {
        let response = try await sendImageInterpretationRequest(imageData: imageData, goal: goal)
        return makeLogEntry(from: response, rawText: "Meal image", userId: userId, loggedAt: loggedAt)
    }
}
