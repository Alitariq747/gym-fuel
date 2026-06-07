import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif
#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif
#if canImport(FirebasePerformance)
import FirebasePerformance
#endif

struct AppTelemetryTrace {
    #if canImport(FirebasePerformance)
    private let trace: Trace?
    #endif

    init(name: String, attributes: [String: String] = [:]) {
        #if canImport(FirebasePerformance)
        trace = Performance.startTrace(name: name)
        attributes.forEach { trace?.setValue($0.value, forAttribute: $0.key) }
        #endif
    }

    func setAttribute(_ value: String, for key: String) {
        #if canImport(FirebasePerformance)
        trace?.setValue(value, forAttribute: key)
        #endif
    }

    func incrementMetric(_ name: String, by value: Int64 = 1) {
        #if canImport(FirebasePerformance)
        trace?.incrementMetric(name, by: value)
        #endif
    }

    func stop() {
        #if canImport(FirebasePerformance)
        trace?.stop()
        #endif
    }
}

enum AppTelemetryService {
    static func track(_ eventName: String, parameters: [String: Any] = [:]) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(eventName, parameters: parameters)
        #endif
    }

    static func startTrace(_ name: String, attributes: [String: String] = [:]) -> AppTelemetryTrace {
        AppTelemetryTrace(name: name, attributes: attributes)
    }

    static func recordNonFatal(
        _ error: Error,
        operation: String,
        attributes: [String: String] = [:]
    ) {
        #if canImport(FirebaseCrashlytics)
        let crashlytics = Crashlytics.crashlytics()
        crashlytics.setCustomValue(operation, forKey: "operation")
        attributes.forEach { crashlytics.setCustomValue($0.value, forKey: $0.key) }
        crashlytics.record(error: error)
        #endif
    }
}
