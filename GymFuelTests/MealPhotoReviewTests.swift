import Foundation
import Testing

@testable import LiftEats

@Suite("Photo review confirmation and cancellation")
@MainActor
struct MealPhotoReviewTests {
    private func model() -> MealPhotoReviewModel {
        MealPhotoReviewModel(source: .photoLibrary) {
            PreparedMealImage(originalData: $0, compressedJPEGData: $0)
        }
    }

    @Test("Preparation alone does not confirm; the image can be confirmed only once")
    func explicitConfirmation() async {
        let model = model()
        #expect(model.confirm() == nil)
        await model.select(data: Data([1]))?.value
        #expect(model.canConfirm)
        #expect(!model.isConfirmed)
        #expect(model.confirm()?.compressedJPEGData == Data([1]))
        #expect(model.confirm() == nil)
        #expect(!model.canConfirm)
        #expect(model.select(data: Data([2])) == nil)
    }

    @Test("Closing while a photo is loading ignores its eventual result")
    func cancelLoading() async {
        let model = model()
        let gate = PhotoLoadGate()
        let loading = model.select { try await gate.load() }
        await gate.waitUntilStarted()
        model.clearSelection()
        await gate.finish(Data([1]))
        await loading?.value
        #expect(model.draft.state == .idle)
        #expect(!model.draft.hasImage)
        #expect(model.confirm() == nil)
    }

    @Test("An older load cannot replace a newer selection")
    func replaceDuringLoading() async {
        let model = model()
        let gate = PhotoLoadGate()
        let older = model.select { try await gate.load() }
        await gate.waitUntilStarted()
        await model.select(data: Data([2]))?.value
        await gate.finish(Data([1]))
        await older?.value
        #expect(model.confirm()?.originalData == Data([2]))
    }

    @Test("Closing during preparation cannot bring back the discarded photo")
    func cancelPreparation() async {
        let gate = PhotoLoadGate()
        let model = MealPhotoReviewModel(source: .camera) { data in
            let jpeg = try await gate.load()
            return PreparedMealImage(originalData: data, compressedJPEGData: jpeg)
        }
        let preparing = model.select(data: Data([1]))
        await gate.waitUntilStarted()
        #expect(model.draft.originalData == Data([1]))
        #expect(model.confirm() == nil)
        model.clearSelection()
        await gate.finish(Data([9]))
        await preparing?.value
        #expect(model.draft.state == .idle)
        #expect(model.confirm() == nil)
    }

    @Test("Preparation failure retains the image and retries without another selection")
    func retryPreparation() async {
        let preparer = FailingOncePreparer()
        let model = MealPhotoReviewModel(source: .camera) { try await preparer.prepare($0) }
        await model.select(data: Data([3]))?.value
        #expect(model.draft.failureMessage != nil)
        #expect(model.draft.originalData == Data([3]))
        #expect(!model.canConfirm)
        await model.retry()?.value
        #expect(model.confirm()?.compressedJPEGData == Data([3]))
        #expect(await preparer.attempts == 2)
    }

    @Test("A failed download can retry the same selected asset")
    func retryLoading() async {
        let loader = FailingOncePreparer()
        let model = model()
        await model.select { try await loader.prepare(Data([4])).originalData }?.value
        #expect(model.draft.failureMessage != nil)
        #expect(!model.draft.hasImage)
        await model.retry()?.value
        #expect(model.confirm()?.originalData == Data([4]))
        #expect(await loader.attempts == 2)
    }

    @Test("Dismissal freezes the displayed draft and ignores late preparation")
    func cancelWhileDismissing() async {
        let gate = PhotoLoadGate()
        let model = MealPhotoReviewModel(source: .camera) { data in
            let jpeg = try await gate.load()
            return PreparedMealImage(originalData: data, compressedJPEGData: jpeg)
        }
        let preparing = model.select(data: Data([1]))
        await gate.waitUntilStarted()
        let visibleDraft = model.draft
        model.cancelPendingWork()
        await gate.finish(Data([9]))
        await preparing?.value
        #expect(model.draft == visibleDraft)
        #expect(model.confirm() == nil)
        model.clearSelection()
        #expect(model.draft.state == .idle)
    }

    @Test("Retake clears a prepared photo and requires a fresh confirmation")
    func retake() async {
        let model = model()
        await model.select(data: Data([1]))?.value
        model.clearSelection()
        #expect(!model.isReviewing)
        #expect(model.confirm() == nil)
        await model.select(data: Data([2]))?.value
        #expect(model.confirm()?.originalData == Data([2]))
    }
}

private actor PhotoLoadGate {
    private var continuation: CheckedContinuation<Data, Error>?
    private var startWaiter: CheckedContinuation<Void, Never>?

    func load() async throws -> Data {
        try await withCheckedThrowingContinuation {
            continuation = $0
            startWaiter?.resume()
            startWaiter = nil
        }
    }

    func waitUntilStarted() async {
        guard continuation == nil else { return }
        await withCheckedContinuation { startWaiter = $0 }
    }

    func finish(_ data: Data) {
        continuation?.resume(returning: data)
        continuation = nil
    }
}

private actor FailingOncePreparer {
    private(set) var attempts = 0

    func prepare(_ data: Data) throws -> PreparedMealImage {
        attempts += 1
        if attempts == 1 { throw MealImagePreparationError.compressionFailed }
        return PreparedMealImage(originalData: data, compressedJPEGData: data)
    }
}
