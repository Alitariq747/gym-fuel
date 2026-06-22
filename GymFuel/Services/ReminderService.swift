//
//  ReminderService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 22/06/2026.
//

import Foundation
import UserNotifications

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
        case .aggressive: "Aggressive"
        }
    }

    var scheduleDescription: String {
        switch self {
        case .quiet:
            "No reminders"
        case .normal:
            "9:00 AM, 2:00 PM and 8:30 PM"
        case .aggressive:
            "Six reminders from 8:00 AM to 10:00 PM"
        }
    }

    fileprivate var times: [ReminderTime] {
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
            "Notifications are disabled for LiftEats. Enable them in iOS Settings to use reminders."
        case .authorizationUnavailable:
            "LiftEats could not enable reminders right now. Please try again."
        }
    }
}

@MainActor
final class ReminderService {
    static let shared = ReminderService()

    private static let allReminderTimes: [ReminderTime] = [
        ReminderTime(hour: 8, minute: 0),
        ReminderTime(hour: 9, minute: 0),
        ReminderTime(hour: 11, minute: 0),
        ReminderTime(hour: 14, minute: 0),
        ReminderTime(hour: 17, minute: 0),
        ReminderTime(hour: 20, minute: 0),
        ReminderTime(hour: 20, minute: 30),
        ReminderTime(hour: 22, minute: 0),
    ]

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    func apply(_ mode: ReminderMode) async throws {
        removePendingReminders()

        guard mode != .quiet else { return }
        guard try await hasAuthorization() else {
            throw ReminderServiceError.authorizationDenied
        }

        do {
            for (index, time) in mode.times.enumerated() {
                try await notificationCenter.add(
                    notificationRequest(for: time, contentIndex: index)
                )
            }
        } catch {
            removePendingReminders()
            throw error
        }
    }

    private func removePendingReminders() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: Self.allReminderTimes.map(\.identifier)
        )
    }

    private func hasAuthorization() async throws -> Bool {
        let settings = await notificationCenter.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return try await notificationCenter.requestAuthorization(options: [.alert, .sound])
        case .denied:
            return false
        @unknown default:
            throw ReminderServiceError.authorizationUnavailable
        }
    }

    private func notificationRequest(
        for time: ReminderTime,
        contentIndex: Int
    ) -> UNNotificationRequest {
        let messages = [
            (
                title: "Quick LiftEats check-in",
                body: "Log your latest meal or workout while it’s still fresh."
            ),
            (
                title: "Keep your day on track",
                body: "A quick meal or workout log keeps your progress accurate."
            ),
            (
                title: "Small log, useful insight",
                body: "Add what you ate or trained and let LiftEats do the rest."
            ),
        ]
        let message = messages[contentIndex % messages.count]

        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: DateComponents(hour: time.hour, minute: time.minute),
            repeats: true
        )

        return UNNotificationRequest(
            identifier: time.identifier,
            content: content,
            trigger: trigger
        )
    }
}

private struct ReminderTime: Hashable {
    let hour: Int
    let minute: Int

    var identifier: String {
        String(format: "lifteats.reminder.%02d%02d", hour, minute)
    }
}
