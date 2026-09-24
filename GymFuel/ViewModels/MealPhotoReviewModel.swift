import Combine
import Foundation

@MainActor
final class MealPhotoReviewModel: ObservableObject {
    typealias Loader = @Sendable () async throws -> Data
    typealias Preparer = @Sendable (Data) async throws -> PreparedMealImage

    @Published private(set) var draft = MealImageDraft()
    @Published private(set) var isConfirmed = false

    let source: MealImageSource
    private let prepare: Preparer
    private var loader: Loader?
    private var task: Task<Void, Never>?
    private var generation = UUID()

    init(source: MealImageSource, prepare: @escaping Preparer = { data in
        let work = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            return try MealImagePreparationService().prepareImageData(from: data)
        }
        return try await withTaskCancellationHandler {
            try await work.value
        } onCancel: {
            work.cancel()
        }
    }) {
        self.source = source
        self.prepare = prepare
    }

    var isReviewing: Bool { draft.state != .idle }
    var canConfirm: Bool { draft.isReadyToSubmit && !isConfirmed }

    @discardableResult
    func select(data: Data) -> Task<Void, Never>? {
        select { data }
    }

    @discardableResult
    func select(load: @escaping Loader) -> Task<Void, Never>? {
        guard !isConfirmed else { return nil }
        clearSelection()
        loader = load
        draft.source = source
        draft.state = .preparing
        let request = generation
        task = Task { [weak self, prepare] in
            do {
                let data = try await load()
                guard let self, self.isCurrent(request) else { return }
                self.draft.originalData = data
                let image = try await prepare(data)
                guard self.isCurrent(request) else { return }
                self.draft.originalData = image.originalData
                self.draft.compressedJPEGData = image.compressedJPEGData
                self.draft.state = .readyToAnalyze
            } catch {
                guard let self, self.isCurrent(request) else { return }
                self.draft.state = .failed(AppErrorMessage.message(
                    for: error,
                    fallback: "We couldn't load that photo. Please try again or choose another."
                ))
            }
        }
        return task
    }

    @discardableResult
    func retry() -> Task<Void, Never>? {
        if let data = draft.originalData {
            return select(data: data)
        } else if let loader {
            return select(load: loader)
        }
        return nil
    }

    func clearSelection() {
        cancelPendingWork()
        draft.reset()
    }

    func cancelPendingWork() {
        task?.cancel()
        task = nil
        generation = UUID()
        loader = nil
    }

    func confirm() -> PreparedMealImage? {
        guard canConfirm,
              let original = draft.originalData,
              let jpeg = draft.compressedJPEGData else { return nil }
        isConfirmed = true
        return PreparedMealImage(originalData: original, compressedJPEGData: jpeg)
    }

    private func isCurrent(_ request: UUID) -> Bool {
        generation == request && !Task.isCancelled && !isConfirmed
    }
}
