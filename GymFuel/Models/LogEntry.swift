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

enum LogEntrySource: String, Codable, Equatable, Hashable, Sendable {
    case text
    case image
    case savedMeal
}

enum LogEntryStatus: String, Codable, Equatable, Hashable, Sendable {
    case analyzing
    case failed
    case succeeded
}

struct LogEntry: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let userId: String
    var source: LogEntrySource
    var status: LogEntryStatus
    var loggedAt: Date
    let type: LogEntryType
    var title: String
    var rawInput: String
    var detail: String?
    var feedback: LogEntryFeedback?
    var image: LogEntryImage?

    init(
        id: String = UUID().uuidString,
        userId: String,
        source: LogEntrySource = .text,
        status: LogEntryStatus = .succeeded,
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
        self.source = source
        self.status = status
        self.loggedAt = loggedAt
        self.type = type
        self.title = title
        self.rawInput = rawInput
        self.detail = detail
        self.feedback = feedback
        self.image = image
    }
}
