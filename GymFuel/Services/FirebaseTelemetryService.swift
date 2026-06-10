import FirebaseAnalytics
import FirebaseCrashlytics
import FirebasePerformance
import Foundation

enum FirebaseTelemetryService {
    @discardableResult
    static func startPerformanceTrace(_ name: String) -> Trace? {
        Performance.startTrace(name: name)
    }

    static func stopPerformanceTrace(
        _ trace: Trace?,
        attributes: [String: String] = [:],
        metrics: [String: Int64] = [:]
    ) {
        guard let trace else { return }

        attributes.forEach { key, value in
            trace.setValue(value, forAttribute: key)
        }

        metrics.forEach { key, value in
            trace.setValue(value, forMetric: key)
        }

        trace.stop()
    }

    static func setUserID(_ userID: String?) {
        Analytics.setUserID(userID)
        Crashlytics.crashlytics().setUserID(userID ?? "")
    }

    static func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }

    static func logAuthEvent(_ action: String, method: String) {
        logEvent("auth_event", parameters: [
            "action": action,
            "method": method,
        ])
    }

    static func logMealAIEvent(_ action: String, source: String) {
        logEvent("meal_ai_event", parameters: [
            "action": action,
            "source": source,
        ])
    }

    static func logSavedMealEvent(_ action: String) {
        logEvent("saved_meal_event", parameters: [
            "action": action,
        ])
    }

    static func logOnboardingEvent(_ action: String, step: String? = nil) {
        var parameters: [String: Any] = [
            "action": action,
        ]

        if let step {
            parameters["step"] = step
        }

        logEvent("onboarding_event", parameters: parameters)
    }

    static func recordNonFatal(
        _ error: Error,
        reason: String,
        metadata: [String: Any] = [:]
    ) {
        metadata.forEach { key, value in
            Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        }

        let nsError = error as NSError
        let wrappedError = NSError(
            domain: nsError.domain,
            code: nsError.code,
            userInfo: nsError.userInfo.merging(["telemetry_reason": reason]) { current, _ in current }
        )

        Crashlytics.crashlytics().record(error: wrappedError)
    }
}
