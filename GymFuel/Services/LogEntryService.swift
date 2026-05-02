//
//  LogEntryService.swift
//  GymFuel
//
//  Created by Codex on 15/04/2026.
//

import Foundation

protocol LogEntryService: Sendable {
    func fetchEntries(
        for userId: String,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [LogEntry]

    func saveEntry(_ entry: LogEntry) async throws
    func updateEntry(_ entry: LogEntry) async throws
    func deleteEntry(userId: String, entryId: String) async throws
}
