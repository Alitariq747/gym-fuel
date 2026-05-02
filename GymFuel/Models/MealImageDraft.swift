import Foundation

enum MealImageSource: String, Sendable {
    case camera
    case photoLibrary
}

enum MealImageAnalysisState: Equatable, Sendable {
    case idle
    case preparing
    case readyToAnalyze
    case analyzing
    case failed(String)
    case succeeded
}

struct MealImageDraft: Equatable, Sendable {
    var source: MealImageSource?
    var originalData: Data?
    var compressedJPEGData: Data?
    var state: MealImageAnalysisState = .idle

    var hasImage: Bool {
        originalData != nil || compressedJPEGData != nil
    }

    var shouldShowCard: Bool {
        hasImage && state != .idle
    }

    var isPending: Bool {
        switch state {
        case .preparing, .readyToAnalyze, .analyzing:
            return true
        case .idle, .failed, .succeeded:
            return false
        }
    }

    var isSuccessful: Bool {
        state == .succeeded
    }

    var canRetry: Bool {
        guard compressedJPEGData != nil else { return false }

        if case .failed = state {
            return true
        }

        return false
    }

    var statusMessage: String {
        switch state {
        case .idle:
            return ""
        case .preparing:
            return "Preparing your image..."
        case .readyToAnalyze:
            return "Getting ready to analyze your meal..."
        case .analyzing:
            return "Analyzing your meal..."
        case .failed(let message):
            return message
        case .succeeded:
            return "Meal analyzed successfully."
        }
    }

    mutating func reset() {
        self = MealImageDraft()
    }
}
