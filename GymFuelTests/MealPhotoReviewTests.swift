import Foundation
import Testing

@testable import Circa

private let reading = "two eggs, a slice of bread"

@Suite("Photo review confirmation and cancellation")
@MainActor
struct MealPhotoReviewTests {
    private func model() -> MealPhotoReviewModel {
        MealPhotoReviewModel(source: .photoLibrary, prepare: {
            PreparedMealImage(originalData: $0, compressedJPEGData: $0)
        }, describe: { _ in reading })
    }

    @Test("A prepared photo is read before it can be confirmed, and confirmed only once")
    func explicitConfirmation() async {
        let model = model()
        #expect(model.confirm() == nil)
        await model.select(data: Data([1]))?.value
        #expect(model.canDescribe)
        #expect(!model.canConfirm)
        #expect(model.confirm() == nil)
        await model.describePhoto()?.value
        #expect(model.isDescribed)
        #expect(model.mealDescription == reading)
        #expect(model.canConfirm)
        #expect(!model.isConfirmed)
        let photo = model.confirm()
        #expect(photo?.image.compressedJPEGData == Data([1]))
        #expect(photo?.description == reading)
        #expect(photo?.isDescriptionEdited == false)
        #expect(model.confirm() == nil)
        #expect(!model.canConfirm)
        #expect(model.select(data: Data([2])) == nil)
    }

    @Test("An edited description is marked as edited; surrounding whitespace is not an edit")
    func editedDescription() async {
        let unchanged = model()
        await unchanged.select(data: Data([1]))?.value
        await unchanged.describePhoto()?.value
        unchanged.mealDescription = "  \(reading)\n"
        let kept = unchanged.confirm()
        #expect(kept?.description == reading)
        #expect(kept?.isDescriptionEdited == false)

        let edited = model()
        await edited.select(data: Data([1]))?.value
        await edited.describePhoto()?.value
        edited.mealDescription = "two eggs, two slices of bread "
        let changed = edited.confirm()
        #expect(changed?.description == "two eggs, two slices of bread")
        #expect(changed?.isDescriptionEdited == true)
    }

    @Test("A blank description cannot be logged")
    func blankDescription() async {
        let model = model()
        await model.select(data: Data([1]))?.value
        await model.describePhoto()?.value
        model.mealDescription = "  \n "
        #expect(!model.canConfirm)
        #expect(model.confirm() == nil)
    }

    @Test("A failed read retries the read without preparing the photo again")
    func retryReading() async {
        let preparations = CallCounter()
        let reader = FailingOncePreparer()
        let model = MealPhotoReviewModel(source: .camera, prepare: { data in
            await preparations.increment()
            return PreparedMealImage(originalData: data, compressedJPEGData: data)
        }, describe: { data in
            _ = try await reader.prepare(data)
            return reading
        })
        await model.select(data: Data([5]))?.value
        await model.describePhoto()?.value
        #expect(model.draft.failureMessage != nil)
        #expect(!model.canConfirm)
        await model.retry()?.value
        #expect(model.isDescribed)
        #expect(model.confirm()?.description == reading)
        #expect(await reader.attempts == 2)
        #expect(await preparations.count == 1)
    }

    @Test("The photo counts as used from Use Photo until a retake, even when the read fails")
    func usedPhotoStage() async {
        let failingRead = FailingOncePreparer()
        let model = MealPhotoReviewModel(source: .camera, prepare: {
            PreparedMealImage(originalData: $0, compressedJPEGData: $0)
        }, describe: { data in
            _ = try await failingRead.prepare(data)
            return reading
        })
        #expect(!model.hasUsedPhoto)
        await model.select(data: Data([1]))?.value
        #expect(!model.hasUsedPhoto)
        await model.describePhoto()?.value
        #expect(model.draft.failureMessage != nil)
        #expect(model.hasUsedPhoto)
        await model.retry()?.value
        #expect(model.isDescribed)
        #expect(model.hasUsedPhoto)
        model.clearSelection()
        #expect(!model.hasUsedPhoto)
    }

    @Test("A photo that failed to load has not been used")
    func failedLoadIsNotUsed() async {
        let preparer = FailingOncePreparer()
        let model = MealPhotoReviewModel(source: .camera, prepare: {
            try await preparer.prepare($0)
        }, describe: { _ in reading })
        await model.select(data: Data([3]))?.value
        #expect(model.draft.failureMessage != nil)
        #expect(!model.hasUsedPhoto)
    }

    @Test("Retaking while the photo is being read ignores the late description")
    func retakeWhileReading() async {
        let gate = PhotoLoadGate()
        let model = MealPhotoReviewModel(source: .camera, prepare: {
            PreparedMealImage(originalData: $0, compressedJPEGData: $0)
        }, describe: { _ in String(decoding: try await gate.load(), as: UTF8.self) })
        await model.select(data: Data([1]))?.value
        let inFlight = model.describePhoto()
        await gate.waitUntilStarted()
        #expect(model.draft.state == .analyzing)
        #expect(model.hasUsedPhoto)
        model.clearSelection()
        await gate.finish(Data("rice and stew".utf8))
        await inFlight?.value
        #expect(model.draft.state == .idle)
        #expect(model.mealDescription.isEmpty)
        #expect(model.confirm() == nil)
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
        await model.describePhoto()?.value
        #expect(model.confirm()?.image.originalData == Data([2]))
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
        #expect(!model.hasUsedPhoto)
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
        let model = MealPhotoReviewModel(source: .camera, prepare: {
            try await preparer.prepare($0)
        }, describe: { _ in reading })
        await model.select(data: Data([3]))?.value
        #expect(model.draft.failureMessage != nil)
        #expect(model.draft.originalData == Data([3]))
        #expect(!model.canDescribe)
        await model.retry()?.value
        await model.describePhoto()?.value
        #expect(model.confirm()?.image.compressedJPEGData == Data([3]))
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
        await model.describePhoto()?.value
        #expect(model.confirm()?.image.originalData == Data([4]))
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
        await model.describePhoto()?.value
        model.clearSelection()
        #expect(!model.isReviewing)
        #expect(model.mealDescription.isEmpty)
        #expect(model.confirm() == nil)
        await model.select(data: Data([2]))?.value
        await model.describePhoto()?.value
        #expect(model.confirm()?.image.originalData == Data([2]))
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

private actor CallCounter {
    private(set) var count = 0

    func increment() { count += 1 }
}

private actor FailingOncePreparer {
    private(set) var attempts = 0

    func prepare(_ data: Data) throws -> PreparedMealImage {
        attempts += 1
        if attempts == 1 { throw MealImagePreparationError.compressionFailed }
        return PreparedMealImage(originalData: data, compressedJPEGData: data)
    }
}
