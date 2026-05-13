import Foundation

enum AppErrorMessage {
    static func message(
        for error: Error,
        fallback: String = "Something went wrong. Please try again."
    ) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription,
           description.isEmpty == false {
            return description
        }

        let nsError = error as NSError

        if isNetworkError(nsError) {
            return "You're offline or the connection is unstable. Please try again."
        }

        if isPermissionError(nsError) {
            return "You don't have permission to do that. Please sign in again and try once more."
        }

        if isUnavailableError(nsError) {
            return "The service is temporarily unavailable. Please try again shortly."
        }

        return fallback
    }

    private static func isNetworkError(_ error: NSError) -> Bool {
        error.domain == NSURLErrorDomain ||
        error.code == 14 ||
        error.code == 4
    }

    private static func isPermissionError(_ error: NSError) -> Bool {
        error.code == 7 ||
        error.code == 16
    }

    private static func isUnavailableError(_ error: NSError) -> Bool {
        error.code == 13 ||
        error.code == 2
    }
}
