//
//  LogEntry.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 15/04/2026.
//

import Foundation

struct LogEntryImage: Codable, Equatable, Hashable, Sendable {
    let storagePath: String
}

struct LogEntry: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let userId: String
    let loggedAt: Date
    let type: LogEntryType
    var title: String
    var rawInput: String
    var detail: String?
    var feedback: LogEntryFeedback?
    var image: LogEntryImage?

    init(
        id: String = UUID().uuidString,
        userId: String,
        loggedAt: Date = Date(),
        type: LogEntryType,
        title: String,
        rawInput: String,
        detail: String? = nil,
        feedback: LogEntryFeedback? = nil,
        image: LogEntryImage? = nil
    ) {
        self.id = id
        self.userId = userId
        self.loggedAt = loggedAt
        self.type = type
        self.title = title
        self.rawInput = rawInput
        self.detail = detail
        self.feedback = feedback
        self.image = image
    }
}
