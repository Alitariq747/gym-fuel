//
//  ReminderService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 22/06/2026.
//

import Foundation
import UserNotifications

private let reminderIdentifierPrefix = "lifteats.reminder."

enum ReminderMode: String, CaseIterable, Identifiable {
    case quiet
    case normal
    case aggressive

    static let preferenceKey = "lifteats.reminder.mode"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .quiet: "Quiet"
        case .normal: "Normal"
        case .aggressive: "Frequent"
        }
    }

    var scheduleDescription: String {
        scheduleDescription(locale: .autoupdatingCurrent)
    }

    func scheduleDescription(locale: Locale) -> String {
        let shown = times.map { $0.formatted(locale: locale) }
        switch self {
        case .quiet:
            return "No reminders"
        case .normal:
            return shown.dropLast().joined(separator: ", ") + " and " + (shown.last ?? "")
        case .aggressive:
            return "\(shown.count) reminders from \(shown.first ?? "") to \(shown.last ?? "")"
        }
    }

    var times: [ReminderTime] {
        switch self {
        case .quiet:
            []
        case .normal:
            [
                ReminderTime(hour: 9, minute: 0),
                ReminderTime(hour: 14, minute: 0),
                ReminderTime(hour: 20, minute: 30),
            ]
        case .aggressive:
            [
                ReminderTime(hour: 8, minute: 0),
                ReminderTime(hour: 11, minute: 0),
                ReminderTime(hour: 14, minute: 0),
                ReminderTime(hour: 17, minute: 0),
                ReminderTime(hour: 20, minute: 0),
                ReminderTime(hour: 22, minute: 0),
            ]
        }
    }
}

enum ReminderServiceError: LocalizedError {
    case authorizationDenied
    case authorizationUnavailable

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            "Notifications are disabled for Circa. Enable them in iOS Settings to use reminders."
        case .authorizationUnavailable:
            "Circa could not enable reminders right now. Please try again."
        }
    }
}

@MainActor
final class ReminderService {
    static let shared = ReminderService()

    private let notificationCenter: any ReminderNotificationCenter
    private let defaults: UserDefaults
    private var latestOperation: Task<Void, Error>?

    init(
        notificationCenter: any ReminderNotificationCenter = SystemReminderNotificationCenter(),
        defaults: UserDefaults = .standard
    ) {
        self.notificationCenter = notificationCenter
        self.defaults = defaults
    }

    func apply(_ mode: ReminderMode, mayAskPermission: Bool, scheduleNow: Bool = true) async throws {
        try await enqueue {
            do {
                try await self.replaceReminders(mode, mayAskPermission: mayAskPermission, scheduleNow: scheduleNow)
                self.defaults.set(mode.rawValue, forKey: ReminderMode.preferenceKey)
            } catch {
                self.defaults.set(ReminderMode.quiet.rawValue, forKey: ReminderMode.preferenceKey)
                throw error
            }
        }
    }

    func restore(isSignedIn: Bool) async throws {
        try await enqueue {
            let mode = ReminderMode(rawValue: self.defaults.string(forKey: ReminderMode.preferenceKey) ?? "") ?? .quiet
            try await self.replaceReminders(isSignedIn ? mode : .quiet, mayAskPermission: false)
        }
    }

    func notificationsOffInIOSSettings() async -> Bool {
        await notificationCenter.authorizationStatus() == .denied
    }

    private func enqueue(_ action: @escaping @MainActor () async throws -> Void) async throws {
        try Task.checkCancellation()
        let previous = latestOperation
        // Once enqueued, finish even if the caller disappears. Sign-out queues
        // its cleanup after this operation, and preference writes stay ordered.
        let operation = Task {
            _ = await previous?.result
            try await action()
        }
        latestOperation = operation
        try await operation.value
    }

    private func replaceReminders(_ mode: ReminderMode, mayAskPermission: Bool, scheduleNow: Bool = true) async throws {
        await removeReminders()

        guard mode != .quiet else { return }
        guard try await hasAuthorization(mayAsk: mayAskPermission) else {
            throw ReminderServiceError.authorizationDenied
        }
        guard scheduleNow else { return }

        do {
            for time in mode.times {
                try await notificationCenter.add(notificationRequest(for: time))
            }
        } catch {
            await removeReminders()
            throw error
        }
    }

    private func removeReminders() async {
        let pending = await notificationCenter.pendingIdentifiers().filter { $0.hasPrefix(reminderIdentifierPrefix) }
        notificationCenter.removePending(withIdentifiers: pending)
        let delivered = await notificationCenter.deliveredIdentifiers().filter { $0.hasPrefix(reminderIdentifierPrefix) }
        notificationCenter.removeDelivered(withIdentifiers: delivered)
    }

    private func hasAuthorization(mayAsk: Bool) async throws -> Bool {
        switch await notificationCenter.authorizationStatus() {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            guard mayAsk else { return false }
            return try await notificationCenter.requestAuthorization()
        case .denied:
            return false
        @unknown default:
            throw ReminderServiceError.authorizationUnavailable
        }
    }

    private func notificationRequest(for time: ReminderTime) -> UNNotificationRequest {
        let message = time.message
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default

        return UNNotificationRequest(
            identifier: time.identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(
                dateMatching: DateComponents(hour: time.hour, minute: time.minute),
                repeats: true
            )
        )
    }
}

struct ReminderTime: Hashable {
    let hour: Int
    let minute: Int

    var identifier: String {
        reminderIdentifierPrefix + String(format: "%02d%02d", hour, minute)
    }

    func formatted(locale: Locale) -> String {
        // A fixed GMT instant formatted in GMT, so no time zone or daylight saving can shift it.
        Date(timeIntervalSinceReferenceDate: TimeInterval(hour * 3600 + minute * 60))
            .formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, timeZone: .gmt))
    }

    var message: (title: String, body: String) {
        switch hour {
        case 8, 9:
            ("Breakfast, in a few words", "Jot down what you had. A few words will do.")
        case 11:
            ("Something between meals?", "Snacks and drinks belong in your food diary, too.")
        case 14:
            ("A moment for lunch", "Write down what you ate while you still remember.")
        case 17:
            ("Keep a note of it", "A few words or a photo can tell the story.")
        case 20:
            ("What was for dinner?", "However you describe it, write it down in Circa.")
        default:
            ("Before you call it a day", "Anything else you’d like to add to your food diary?")
        }
    }
}
