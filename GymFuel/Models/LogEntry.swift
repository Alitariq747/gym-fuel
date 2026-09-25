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

enum LogEntryImageUploadStatus: String, Codable, Equatable, Hashable, Sendable {
    case localOnly
    case uploading
    case uploaded
    case failed
}

enum LogEntrySource: String, Codable, Equatable, Hashable, Sendable {
    case text
    case image
    case savedMeal

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = LogEntrySource(rawValue: rawValue) ?? .text
    }
}

enum LogEntryStatus: String, Codable, Equatable, Hashable, Sendable {
    case analyzing
    case failed
    case succeeded

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = LogEntryStatus(rawValue: rawValue) ?? .succeeded
    }
}

struct LogEntry: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let userId: String
    var source: LogEntrySource
    var status: LogEntryStatus
    var loggedAt: Date
    var title: String
    var rawInput: String
    var detail: String?
    var feedback: LogEntryFeedback?
    var image: LogEntryImage?
    var imageUploadStatus: LogEntryImageUploadStatus?
    var isRawInputReworded: Bool?

    init(
        id: String = UUID().uuidString,
        userId: String,
        source: LogEntrySource = .text,
        status: LogEntryStatus = .succeeded,
        loggedAt: Date = Date(),
        title: String,
        rawInput: String,
        detail: String? = nil,
        feedback: LogEntryFeedback? = nil,
        image: LogEntryImage? = nil,
        imageUploadStatus: LogEntryImageUploadStatus? = nil,
        isRawInputReworded: Bool? = nil
    ) {
        self.id = id
        self.userId = userId
        self.source = source
        self.status = status
        self.loggedAt = loggedAt
        self.title = title
        self.rawInput = rawInput
        self.detail = detail
        self.feedback = feedback
        self.image = image
        self.imageUploadStatus = imageUploadStatus
        self.isRawInputReworded = isRawInputReworded
    }
}

extension LogEntry {
    /// Saved entries already carry this value, so it never changes.
    static let photoRawInputPlaceholder = "Meal image"

    /// `design.md` rule 3: a photo's `rawInput` is Circa's description until the person rewords it.
    var isRawInputGenerated: Bool {
        source == .image && isRawInputReworded != true
    }
}
