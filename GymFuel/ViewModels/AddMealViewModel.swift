//
//  AddMealViewModel.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/12/2025.
//

import Foundation
import SwiftUI

@MainActor
final class AddMealViewModel: ObservableObject {
    @Published var descriptionText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var parsed: ParsedMeal? = nil

    private let service: MealParsingService

    init(service: MealParsingService) {
        self.service = service
    }

    func parse() async {
        errorMessage = nil
        parsed = nil

        let input = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            errorMessage = "Please describe your meal."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await service.parseMeal(description: input)
            parsed = result
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reset() {
        descriptionText = ""
        parsed = nil
        errorMessage = nil
        isLoading = false
    }
}
