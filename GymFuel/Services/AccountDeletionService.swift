//
//  AccountDeletionService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 17/02/2026.
//

import Foundation
import FirebaseFunctions

protocol AccountDeletionService {
    func deleteCurrentAccount() async throws
}

final class FirebaseAccountDeletionService: AccountDeletionService {
    private let functions: Functions

    init(functions: Functions = Functions.functions(region: "us-central1")) {
        self.functions = functions
    }

    func deleteCurrentAccount() async throws {
        _ = try await functions
            .httpsCallable("deleteAccount")
            .call()
    }
}
