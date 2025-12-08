//
//  MealAiClient.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/12/2025.
//

import Foundation

final class MealAiClient {
    static let shared = MealAiClient()
    
    private let baseURL = URL(string: "http://localhost:5001")!
    
    private init() {}
    
    struct RequestBody: Encodable {
        let description: String
        let goal: String?
        let dayType: String?
    }
    
    func estimateMacros(description: String, goal: String?, dayType: String?) async throws -> MealAIResponse {
        
        let url = baseURL.appendingPathComponent("/api/estimate-meal")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = RequestBody(description: description, goal: goal, dayType: dayType)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data,response) = try await URLSession.shared.data(for: request)
       
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                   if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let message = errorJSON["error"] as? String {
                       throw NSError(domain: "MealAIClient", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
                   } else {
                       throw NSError(domain: "MealAIClient", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error \(http.statusCode)"])
                   }
               }
        
        let decoded = try JSONDecoder().decode(MealAIResponse.self, from: data)
        return decoded
    }
}
