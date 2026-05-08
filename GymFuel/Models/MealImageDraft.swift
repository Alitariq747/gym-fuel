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

    var previewData: Data? {
        originalData ?? compressedJPEGData
    }

    var hasPreparedPayload: Bool {
        compressedJPEGData != nil
    }

    var isReadyToSubmit: Bool {
        state == .readyToAnalyze && hasPreparedPayload
    }

    var failureMessage: String? {
        guard case .failed(let message) = state else { return nil }
        return message
    }

    mutating func reset() {
        self = MealImageDraft()
    }
}
