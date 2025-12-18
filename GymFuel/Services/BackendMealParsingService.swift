//
//  BackendMealService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/12/2025.
//

import Foundation

final class BackendMealParsingService: MealParsingService {
    struct RequestBody: Codable {
        let description: String
    }

    enum ServiceError: Error {
        case invalidURL
        case httpError(status: Int, message: String?)
        case decodingFailed
    }

    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func parseMeal(description: String) async throws -> ParsedMeal {
        let url = baseURL.appendingPathComponent("api/estimate-meal")


        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(RequestBody(description: description))

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.httpError(status: -1, message: "No HTTP response")
        }

        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8)
            throw ServiceError.httpError(status: http.statusCode, message: msg)
        }

        do {
            let decoded = try JSONDecoder().decode(ParsedMeal.self, from: data)
            return try decoded.validated()
        } catch let validationError as MealParseValidationError {
            throw validationError
        } catch {
            throw ServiceError.decodingFailed
        }

    }
}
