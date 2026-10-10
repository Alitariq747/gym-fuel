import Foundation
import Testing
import UserNotifications

@testable import Circa

@Suite("Fixed reminders")
@MainActor
struct ReminderServiceTests {
    @Test func scheduleTextIsBuiltFromTheTimes() {
        let twelveHour = Locale(identifier: "en_US")
        let twentyFourHour = Locale(identifier: "en_GB")
        func spaced(_ text: String) -> String { text.replacingOccurrences(of: "\u{202F}", with: " ") }
        #expect(ReminderMode.quiet.scheduleDescription(locale: twelveHour) == "No reminders")
        #expect(spaced(ReminderMode.normal.scheduleDescription(locale: twelveHour)) == "9:00 AM, 2:00 PM and 8:30 PM")
        #expect(spaced(ReminderMode.aggressive.scheduleDescription(locale: twelveHour)) == "6 reminders from 8:00 AM to 10:00 PM")
        let normal24 = ReminderMode.normal.scheduleDescription(locale: twentyFourHour)
        #expect(normal24.hasSuffix(", 14:00 and 20:30") && !normal24.contains("AM"))
        let frequent24 = ReminderMode.aggressive.scheduleDescription(locale: twentyFourHour)
        #expect(frequent24.hasPrefix("6 reminders from ") && frequent24.hasSuffix(" to 22:00") && !frequent24.contains("AM"))
    }

    @Test(arguments: [UNAuthorizationStatus.denied, .notDetermined, .authorized, .provisional])
    func notificationsOffOnlyWhenDenied(_ status: UNAuthorizationStatus) async throws {
        try await withService { service, center, _ in
            center.status = status
            #expect(await service.notificationsOffInIOSSettings() == (status == .denied))
        }
    }

    @Test(arguments: [ReminderMode.normal, .aggressive])
    func exactScheduleAndCopy(_ mode: ReminderMode) async throws {
        try await withService { service, center, defaults in
            try await service.apply(mode, mayAskPermission: true)

            let times = mode == .normal ? [(9, 0), (14, 0), (20, 30)]
                : [(8, 0), (11, 0), (14, 0), (17, 0), (20, 0), (22, 0)]
            let copy: [Int: (String, String)] = [
                8: ("Breakfast, in a few words", "Jot down what you had. A few words will do."),
                9: ("Breakfast, in a few words", "Jot down what you had. A few words will do."),
                11: ("Something between meals?", "Snacks and drinks belong in your food diary, too."),
                14: ("A moment for lunch", "Write down what you ate while you still remember."),
                17: ("Keep a note of it", "A few words or a photo can tell the story."),
                20: ("What was for dinner?", "However you describe it, write it down in Circa."),
                22: ("Before you call it a day", "Anything else you’d like to add to your food diary?"),
            ]
            #expect(center.pending.count == times.count)
            for (hour, minute) in times {
                let identifier = String(format: "lifteats.reminder.%02d%02d", hour, minute)
                let request = try #require(center.pending[identifier])
                let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
                #expect(trigger.repeats)
                #expect(trigger.dateComponents == DateComponents(hour: hour, minute: minute))
                #expect(request.content.title == copy[hour]?.0)
                #expect(request.content.body == copy[hour]?.1)
                #expect(request.content.sound != nil)
                #expect(request.content.badge == nil)
                #expect(request.content.userInfo.isEmpty)
            }
            #expect(center.permissionRequests == 0)
            #expect(defaults.string(forKey: ReminderMode.preferenceKey) == mode.rawValue)
        }
    }

    @Test func transitionsReplaceRatherThanAccumulate() async throws {
        try await withService { service, center, defaults in
            try await service.apply(.normal, mayAskPermission: true)
            try await service.apply(.aggressive, mayAskPermission: true)
            #expect(Set(center.pending.keys) == Set([
                "lifteats.reminder.0800", "lifteats.reminder.1100", "lifteats.reminder.1400",
                "lifteats.reminder.1700", "lifteats.reminder.2000", "lifteats.reminder.2200",
            ]))
            try await service.apply(.normal, mayAskPermission: true)
            try await service.apply(.normal, mayAskPermission: true)
            #expect(Set(center.pending.keys) == Set([
                "lifteats.reminder.0900", "lifteats.reminder.1400", "lifteats.reminder.2030",
            ]))
            try await service.apply(.quiet, mayAskPermission: false)
            #expect(center.pending.isEmpty)
            #expect(defaults.string(forKey: ReminderMode.preferenceKey) == "quiet")
        }
    }

    @Test func migratesLegacyAndExperimentalRequestsOnly() async throws {
        try await withService { service, center, _ in
            center.seed("lifteats.reminder.0900")
            center.seed("lifteats.reminder.1791207000")
            center.seed("unrelated.request")
            try await service.apply(.normal, mayAskPermission: true)
            #expect(center.pending.count == 4)
            #expect(center.pending["lifteats.reminder.1791207000"] == nil)
            #expect(center.pending["unrelated.request"] != nil)
            #expect(center.delivered == ["unrelated.request"])
        }
    }

    @Test func quietAndNotNowNeverAskPermission() async throws {
        try await withService { service, center, defaults in
            center.status = .notDetermined
            center.seed("lifteats.reminder.0900")
            try await service.apply(.quiet, mayAskPermission: false)
            #expect(center.pending.isEmpty)
            #expect(center.delivered.isEmpty)
            #expect(center.permissionRequests == 0)
            #expect(center.authorizationReads == 0)
            #expect(defaults.string(forKey: ReminderMode.preferenceKey) == "quiet")
        }
    }

    @Test func onboardingSavesChoiceAndSignInSchedulesIt() async throws {
        try await withService { service, center, defaults in
            center.status = .notDetermined
            center.seed("lifteats.reminder.0900")
            try await service.apply(.normal, mayAskPermission: true, scheduleNow: false)
            #expect(center.permissionRequests == 1)
            #expect(center.pending.isEmpty)
            #expect(center.delivered.isEmpty)
            #expect(defaults.string(forKey: ReminderMode.preferenceKey) == "normal")
            try await service.restore(isSignedIn: false)
            #expect(center.pending.isEmpty)
            try await service.restore(isSignedIn: true)
            #expect(center.pending.count == 3)
            #expect(center.permissionRequests == 1)
        }
    }

    @Test(arguments: [false, true])
    func onboardingDenialSavesQuiet(_ throwsError: Bool) async throws {
        try await withService { service, center, defaults in
            center.status = .notDetermined
            center.permissionGranted = false
            center.permissionThrows = throwsError
            await #expect(throws: (any Error).self) {
                try await service.apply(.normal, mayAskPermission: true, scheduleNow: false)
            }
            #expect(center.pending.isEmpty)
            #expect(defaults.string(forKey: ReminderMode.preferenceKey) == "quiet")
        }
    }

    @Test func explicitEnableAsksOnce() async throws {
        try await withService { service, center, _ in
            center.status = .notDetermined
            try await service.apply(.normal, mayAskPermission: true)
            try await service.apply(.aggressive, mayAskPermission: true)
            #expect(center.permissionRequests == 1)
            #expect(center.pending.count == 6)
        }
    }

    @Test(arguments: [UNAuthorizationStatus.denied, .notDetermined])
    func automaticRestoreDoesNotAskOrErasePreference(_ status: UNAuthorizationStatus) async throws {
        try await withService { service, center, defaults in
            defaults.set("normal", forKey: ReminderMode.preferenceKey)
            center.status = status
            center.seed("lifteats.reminder.0900")
            await #expect(throws: ReminderServiceError.self) {
                try await service.restore(isSignedIn: true)
            }
            #expect(center.pending.isEmpty)
            #expect(center.permissionRequests == 0)
            #expect(defaults.string(forKey: ReminderMode.preferenceKey) == "normal")
            center.status = .authorized
            try await service.restore(isSignedIn: true)
            #expect(center.pending.count == 3)
        }
    }

    @Test(arguments: [UNAuthorizationStatus.authorized, .provisional])
    func acceptedAuthorizationNeedsNoPrompt(_ status: UNAuthorizationStatus) async throws {
        try await withService { service, center, _ in
            center.status = status
            try await service.apply(.normal, mayAskPermission: false)
            #expect(center.pending.count == 3)
            #expect(center.permissionRequests == 0)
        }
    }

    #if os(iOS)
    @Test func ephemeralAuthorizationNeedsNoPrompt() async throws {
        try await acceptedAuthorizationNeedsNoPrompt(.ephemeral)
    }
    #endif

    @Test func previouslyDeniedPermissionDoesNotPromptAgain() async throws {
        try await withService { service, center, defaults in
            center.status = .denied
            await #expect(throws: ReminderServiceError.self) {
                try await service.apply(.normal, mayAskPermission: true)
            }
            #expect(center.permissionRequests == 0)
            #expect(center.pending.isEmpty)
            #expect(defaults.string(forKey: ReminderMode.preferenceKey) == "quiet")
        }
    }

    @Test(arguments: [false, true])
    func deniedOrFailedPermissionFallsBackToQuiet(_ throwsError: Bool) async throws {
        try await withService { service, center, defaults in
            defaults.set("aggressive", forKey: ReminderMode.preferenceKey)
            center.status = .notDetermined
            center.permissionGranted = false
            center.permissionThrows = throwsError
            center.seed("lifteats.reminder.0900")
            await #expect(throws: (any Error).self) {
                try await service.apply(.normal, mayAskPermission: true)
            }
            #expect(center.pending.isEmpty)
            #expect(center.delivered.isEmpty)
            #expect(defaults.string(forKey: ReminderMode.preferenceKey) == "quiet")
        }
    }

    @Test func partialSchedulingFailureClearsAndQueueRecovers() async throws {
        try await withService { service, center, defaults in
            center.seed("unrelated.request")
            center.failAddNumber = 2
            await #expect(throws: FakeReminderError.self) {
                try await service.apply(.normal, mayAskPermission: true)
            }
            #expect(Set(center.pending.keys) == ["unrelated.request"])
            #expect(defaults.string(forKey: ReminderMode.preferenceKey) == "quiet")
            center.failAddNumber = nil
            try await service.apply(.aggressive, mayAskPermission: true)
            #expect(center.pending.count == 7)
        }
    }

    @Test func automaticSchedulingFailurePreservesMode() async throws {
        try await withService { service, center, defaults in
            defaults.set("aggressive", forKey: ReminderMode.preferenceKey)
            center.failAddNumber = 2
            await #expect(throws: FakeReminderError.self) {
                try await service.restore(isSignedIn: true)
            }
            #expect(center.pending.isEmpty)
            #expect(defaults.string(forKey: ReminderMode.preferenceKey) == "aggressive")
        }
    }

    @Test func signOutClearsAndSignInRestoresSavedMode() async throws {
        try await withService { service, center, defaults in
            try await service.apply(.aggressive, mayAskPermission: true)
            center.seed("lifteats.reminder.1791207000")
            center.seed("unrelated.request")
            try await service.restore(isSignedIn: false)
            #expect(Set(center.pending.keys) == ["unrelated.request"])
            #expect(center.delivered == ["unrelated.request"])
            #expect(defaults.string(forKey: ReminderMode.preferenceKey) == "aggressive")
            try await service.restore(isSignedIn: true)
            #expect(center.pending.count == 7)
            #expect(center.permissionRequests == 0)
        }
    }

    @Test(arguments: [true, false])
    func missingOrInvalidPreferenceStaysQuiet(_ missing: Bool) async throws {
        try await withService { service, center, defaults in
            if !missing { defaults.set("obsolete", forKey: ReminderMode.preferenceKey) }
            center.status = .notDetermined
            center.seed("lifteats.reminder.0900")
            try await service.restore(isSignedIn: true)
            #expect(center.pending.isEmpty)
            #expect(center.permissionRequests == 0)
        }
    }

    @Test func signOutWaitsForInFlightApplyEvenWhenCallerIsCancelled() async throws {
        try await withService { service, center, defaults in
            let gate = ReminderTestGate()
            center.firstAddGate = gate
            let applying = Task { try await service.apply(.normal, mayAskPermission: true) }
            await gate.waitUntilPaused()
            #expect(defaults.string(forKey: ReminderMode.preferenceKey) == nil)
            applying.cancel()
            let signOutStarted = ReminderTestSignal()
            let signingOut = Task {
                signOutStarted.signal()
                try await service.restore(isSignedIn: false)
            }
            await signOutStarted.wait()
            gate.release()
            try await applying.value
            try await signingOut.value
            #expect(center.pending.isEmpty)
            #expect(center.delivered.isEmpty)
            #expect(defaults.string(forKey: ReminderMode.preferenceKey) == "normal")
        }
    }

    @Test func queuedRestoreReadsTheCommittedPreference() async throws {
        try await withService { service, center, defaults in
            defaults.set("quiet", forKey: ReminderMode.preferenceKey)
            let gate = ReminderTestGate()
            center.firstAddGate = gate
            let applying = Task { try await service.apply(.aggressive, mayAskPermission: true) }
            await gate.waitUntilPaused()
            let restoreStarted = ReminderTestSignal()
            let restoring = Task {
                restoreStarted.signal()
                try await service.restore(isSignedIn: true)
            }
            await restoreStarted.wait()
            gate.release()
            try await applying.value
            try await restoring.value
            #expect(center.pending.count == 6)
            #expect(defaults.string(forKey: ReminderMode.preferenceKey) == "aggressive")
        }
    }

    @Test func cancelledLifecycleCallbackCannotRestoreAfterSignOut() async throws {
        try await withService { service, center, defaults in
            defaults.set("normal", forKey: ReminderMode.preferenceKey)
            let gate = ReminderTestGate()
            let staleCallback = Task {
                await gate.pause()
                try await service.restore(isSignedIn: true)
            }
            await gate.waitUntilPaused()
            staleCallback.cancel()
            try await service.restore(isSignedIn: false)
            gate.release()
            await #expect(throws: CancellationError.self) { try await staleCallback.value }
            #expect(center.pending.isEmpty)
            #expect(center.authorizationReads == 0)
        }
    }

    private func withService(
        _ run: @MainActor (ReminderService, FakeReminderNotificationCenter, UserDefaults) async throws -> Void
    ) async throws {
        let domain = "ReminderServiceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        let center = FakeReminderNotificationCenter()
        try await run(ReminderService(notificationCenter: center, defaults: defaults), center, defaults)
    }
}

private enum FakeReminderError: Error { case failed }

@MainActor
private final class FakeReminderNotificationCenter: ReminderNotificationCenter {
    var status: UNAuthorizationStatus = .authorized
    var permissionGranted = true
    var permissionThrows = false
    var permissionRequests = 0
    var authorizationReads = 0
    var pending: [String: UNNotificationRequest] = [:]
    var delivered: Set<String> = []
    var failAddNumber: Int?
    var firstAddGate: ReminderTestGate?
    private var addCount = 0

    func authorizationStatus() async -> UNAuthorizationStatus {
        authorizationReads += 1
        return status
    }
    func requestAuthorization() async throws -> Bool {
        permissionRequests += 1
        if permissionThrows { throw FakeReminderError.failed }
        status = permissionGranted ? .authorized : .denied
        return permissionGranted
    }
    func pendingIdentifiers() async -> [String] { Array(pending.keys) }
    func deliveredIdentifiers() async -> [String] { Array(delivered) }
    func removePending(withIdentifiers identifiers: [String]) {
        for identifier in identifiers { pending[identifier] = nil }
    }
    func removeDelivered(withIdentifiers identifiers: [String]) {
        delivered.subtract(identifiers)
    }
    func add(_ request: UNNotificationRequest) async throws {
        addCount += 1
        if addCount == 1 { await firstAddGate?.pause() }
        if addCount == failAddNumber { throw FakeReminderError.failed }
        pending[request.identifier] = request
    }
    func seed(_ identifier: String) {
        pending[identifier] = UNNotificationRequest(
            identifier: identifier, content: UNMutableNotificationContent(), trigger: nil
        )
        delivered.insert(identifier)
    }
}

@MainActor
private final class ReminderTestSignal {
    private var signaled = false
    private var continuation: CheckedContinuation<Void, Never>?

    func signal() {
        signaled = true
        continuation?.resume()
        continuation = nil
    }
    func wait() async {
        if signaled { return }
        await withCheckedContinuation { continuation = $0 }
    }
}

@MainActor
private final class ReminderTestGate {
    private let paused = ReminderTestSignal()
    private let released = ReminderTestSignal()

    func pause() async {
        paused.signal()
        await released.wait()
    }
    func waitUntilPaused() async { await paused.wait() }
    func release() { released.signal() }
}
