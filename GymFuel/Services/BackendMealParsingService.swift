//
//  BackendMealService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/12/2025.
//

import Foundation
import os

final class BackendMealParsingService: MealParsingService {
    struct RequestBody: Codable {
        let description: String
    }

    enum ServiceError: Error {
        case invalidURL
        case httpError(status: Int, message: String?)
        case decodingFailed
    }

    private static let logger = Logger(subsystem: "GymFuel", category: "MealParsing")

    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = BackendMealParsingService.makeSession()) {
        self.baseURL = baseURL
        self.session = session
    }

    func parseMeal(_ input: MealParseInput) async throws -> ParsedMeal {
        switch input {
        case let .text(description):
            return try await parseTextMeal(description: description)
        case let .photo(data, mimeType, filename):
            return try await parsePhotoMeal(
                imageData: data,
                mimeType: mimeType,
                filename: filename
            )
        }
    }

    private static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }

    private func logHTTPStatus(response: URLResponse) {
        #if DEBUG
        if let http = response as? HTTPURLResponse {
            Self.logger.debug("Meal parsing response: \(http.statusCode)")
        } else {
            Self.logger.debug("Meal parsing response: non-HTTP response")
        }
        #endif
    }

    private func logDecodeFailure(_ reason: String) {
        #if DEBUG
        Self.logger.debug("Meal parsing decode failure: \(reason)")
        #endif
    }

    private func parseTextMeal(description: String) async throws -> ParsedMeal {
        let url = baseURL.appendingPathComponent("api/estimate-meal")


        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(RequestBody(description: description))

        let (data, response) = try await session.data(for: request)
        logHTTPStatus(response: response)
        return try decodeParsedMeal(data: data, response: response)
    }

    private func parsePhotoMeal(
        imageData: Data,
        mimeType: String,
        filename: String
    ) async throws -> ParsedMeal {
        let url = baseURL.appendingPathComponent("api/estimate-meal-image")
        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody = makeMultipartBody(
            imageData: imageData,
            mimeType: mimeType,
            filename: filename,
            boundary: boundary
        )

        let (data, response) = try await session.data(for: request)
        logHTTPStatus(response: response)
        return try decodeParsedMeal(data: data, response: response)
    }

    private func decodeParsedMeal(data: Data, response: URLResponse) throws -> ParsedMeal {
        guard let http = response as? HTTPURLResponse else {
            logDecodeFailure("Missing HTTP response")
            throw ServiceError.httpError(status: -1, message: "No HTTP response")
        }

        guard (200...299).contains(http.statusCode) else {
            logDecodeFailure("HTTP \(http.statusCode)")
            let msg = String(data: data, encoding: .utf8)
            throw ServiceError.httpError(status: http.statusCode, message: msg)
        }

        do {
            let decoded = try JSONDecoder().decode(ParsedMeal.self, from: data)
            return try decoded.validated()
        } catch let validationError as MealParseValidationError {
            logDecodeFailure("Validation error")
            throw validationError
        } catch {
            logDecodeFailure("Decoding failed")
            throw ServiceError.decodingFailed
        }
    }

    private func makeMultipartBody(
        imageData: Data,
        mimeType: String,
        filename: String,
        boundary: String
    ) -> Data {
        var body = Data()

        body.appendMultipartFileField(
            name: "image",
            filename: filename,
            mimeType: mimeType,
            fileData: imageData,
            boundary: boundary
        )

        body.appendString("--\(boundary)--\r\n")
        return body
    }
}

extension BackendMealParsingService.ServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid parsing URL."
        case let .httpError(status, message):
            if let message, !message.isEmpty {
                return "Parsing failed (\(status)): \(message)"
            }
            return "Parsing failed with status \(status)."
        case .decodingFailed:
            return "Couldn't decode meal estimate from server."
        }
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        append(data)
    }

    mutating func appendMultipartFileField(
        name: String,
        filename: String,
        mimeType: String,
        fileData: Data,
        boundary: String
    ) {
        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        appendString("Content-Type: \(mimeType)\r\n\r\n")
        append(fileData)
        appendString("\r\n")
    }
}
