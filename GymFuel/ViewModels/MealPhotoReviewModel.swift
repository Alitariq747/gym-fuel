import Combine
import Foundation

@MainActor
final class MealPhotoReviewModel: ObservableObject {
    typealias Loader = @Sendable () async throws -> Data
    typealias Preparer = @Sendable (Data) async throws -> PreparedMealImage
    typealias Describer = @Sendable (Data) async throws -> String

    @Published private(set) var draft = MealImageDraft()
    @Published private(set) var isConfirmed = false
    @Published var mealDescription = ""

    let source: MealImageSource
    private let prepare: Preparer
    private let describe: Describer
    private var generatedDescription = ""
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
    }, describe: @escaping Describer = { data in
        try await BackendLogInterpretationService().describeMealImage(data)
    }) {
        self.source = source
        self.prepare = prepare
        self.describe = describe
    }

    var isReviewing: Bool { draft.state != .idle }
    var isDescribed: Bool { draft.state == .succeeded }
    /// A failed load has no prepared payload, so `.failed` with one means the read failed.
    var hasUsedPhoto: Bool {
        switch draft.state {
        case .analyzing, .succeeded: true
        case .failed: draft.hasPreparedPayload
        case .idle, .preparing, .readyToAnalyze: false
        }
    }
    var canDescribe: Bool { draft.isReadyToSubmit && !isConfirmed }
    var canConfirm: Bool { isDescribed && !isConfirmed && !trimmedDescription.isEmpty }
    private var trimmedDescription: String { mealDescription.trimmingCharacters(in: .whitespacesAndNewlines) }

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
    func describePhoto() -> Task<Void, Never>? {
        guard canDescribe, let jpeg = draft.compressedJPEGData else { return nil }
        draft.state = .analyzing
        let request = generation
        task = Task { [weak self, describe] in
            do {
                let text = try await describe(jpeg).trimmingCharacters(in: .whitespacesAndNewlines)
                guard let self, self.isCurrent(request) else { return }
                self.generatedDescription = text
                self.mealDescription = text
                self.draft.state = .succeeded
            } catch {
                guard let self, self.isCurrent(request) else { return }
                self.draft.state = .failed(AppErrorMessage.message(
                    for: error,
                    fallback: "We couldn't read this photo. Please try again."
                ))
            }
        }
        return task
    }

    @discardableResult
    func retry() -> Task<Void, Never>? {
        if draft.hasPreparedPayload {
            draft.state = .readyToAnalyze
            return describePhoto()
        } else if let data = draft.originalData {
            return select(data: data)
        } else if let loader {
            return select(load: loader)
        }
        return nil
    }

    func clearSelection() {
        cancelPendingWork()
        draft.reset()
        mealDescription = ""
        generatedDescription = ""
    }

    func cancelPendingWork() {
        task?.cancel()
        task = nil
        generation = UUID()
        loader = nil
    }

    func confirm() -> ConfirmedMealPhoto? {
        guard canConfirm,
              let original = draft.originalData,
              let jpeg = draft.compressedJPEGData else { return nil }
        isConfirmed = true
        return ConfirmedMealPhoto(
            image: PreparedMealImage(originalData: original, compressedJPEGData: jpeg),
            description: trimmedDescription,
            isDescriptionEdited: trimmedDescription != generatedDescription
        )
    }

    private func isCurrent(_ request: UUID) -> Bool {
        generation == request && !Task.isCancelled && !isConfirmed
    }
}
