import Foundation
import FirebaseAuth
import FirebaseAppCheck

final class BackendLogInterpretationService: LogInterpretationService, @unchecked Sendable {
    private let baseURL: URL

    init(baseURL: URL = URL(string: "https://mas-harbor-mating-lines.trycloudflare.com")!) {
        self.baseURL = baseURL
    }

    private struct TextInterpretationRequest: Codable {
        var text: String
        var goal: GoalType
    }

    private struct ImageInterpretationRequest: Codable {
        var imageBase64: String
        var goal: GoalType
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

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(TextInterpretationResponse.self, from: data)
    }

    private func sendImageInterpretationRequest(_ requestData: Data) async throws -> TextInterpretationResponse {
        let url = baseURL.appendingPathComponent("interpretMealImage")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData

        let idToken = try await Auth.auth().currentUser?.getIDToken() ?? ""
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let appCheckToken = try await AppCheck.appCheck().token(forcingRefresh: false).token
        request.setValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(TextInterpretationResponse.self, from: data)
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
        let request = ImageInterpretationRequest(
            imageBase64: imageData.base64EncodedString(),
            goal: goal
        )
        let requestData = try JSONEncoder().encode(request)
        let response = try await sendImageInterpretationRequest(requestData)
        return makeLogEntry(from: response, rawText: "Meal image", userId: userId, loggedAt: loggedAt)
    }
}
