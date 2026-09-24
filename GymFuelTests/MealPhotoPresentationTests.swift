import Foundation
import Testing
@testable import LiftEats

struct MealPhotoPresentationTests {
    private let date = Date(timeIntervalSince1970: 1_700_000_000)
    private let image = PreparedMealImage(originalData: Data([1]), compressedJPEGData: Data([2]))

    @Test("Opening again cannot replace an active session or its logging date")
    func preventReopening() throws {
        var presentation = MealPhotoPresentation()
        presentation.present(source: .camera, loggedAt: date)
        let id = try #require(presentation.session?.id)
        presentation.present(source: .photoLibrary, loggedAt: date.addingTimeInterval(100))
        #expect(presentation.session?.id == id)
        #expect(presentation.session?.source == .camera)
        #expect(presentation.session?.loggedAt == date)
    }

    @Test("Dismissal without confirmation never yields a submission")
    func dismissWithoutPhoto() throws {
        var presentation = MealPhotoPresentation()
        presentation.present(source: .photoLibrary, loggedAt: date)
        let id = try #require(presentation.session?.id)
        presentation.dismiss()
        presentation.confirm(image, source: .photoLibrary)
        #expect(presentation.isActive)
        let cancelled = presentation.finishDismissal(sessionID: id)
        #expect(cancelled == nil)
        #expect(!presentation.isActive)
    }

    @Test("Confirmation submits once after closing, retaining the original logging date")
    func confirmOnceAfterClosing() throws {
        var presentation = MealPhotoPresentation()
        presentation.present(source: .camera, loggedAt: date)
        let id = try #require(presentation.session?.id)
        let premature = presentation.finishDismissal(sessionID: id)
        #expect(premature == nil)
        presentation.confirm(image, source: .camera)
        presentation.confirm(PreparedMealImage(originalData: Data([9]), compressedJPEGData: Data([9])), source: .camera)
        presentation.dismiss()
        presentation.present(source: .photoLibrary, loggedAt: .now)
        #expect(presentation.isActive)
        #expect(presentation.isDismissing)
        let result = presentation.finishDismissal(sessionID: id)
        let submission = try #require(result)
        #expect(submission.image.compressedJPEGData == image.compressedJPEGData)
        #expect(submission.loggedAt == date)
        let repeated = presentation.finishDismissal(sessionID: id)
        #expect(repeated == nil)
        #expect(!presentation.isActive)
    }

    @Test("A confirmation from another source is ignored")
    func rejectWrongSource() {
        var presentation = MealPhotoPresentation()
        presentation.present(source: .camera, loggedAt: date)
        presentation.confirm(image, source: .photoLibrary)
        #expect(!presentation.isDismissing)
    }

    @Test("Forced cancellation discards a confirmed image and its late completion")
    func cancelConfirmedPhoto() throws {
        var presentation = MealPhotoPresentation()
        presentation.present(source: .camera, loggedAt: date)
        let id = try #require(presentation.session?.id)
        presentation.confirm(image, source: .camera)
        presentation.cancel()
        let cancelled = presentation.finishDismissal(sessionID: id)
        #expect(cancelled == nil)
        #expect(!presentation.isActive)
    }

    @Test("An old animation completion cannot close a newly opened panel")
    func ignoreStaleCompletion() throws {
        var presentation = MealPhotoPresentation()
        presentation.present(source: .camera, loggedAt: date)
        let oldID = try #require(presentation.session?.id)
        presentation.dismiss()
        presentation.cancel()
        presentation.present(source: .photoLibrary, loggedAt: date)
        let newID = try #require(presentation.session?.id)
        presentation.confirm(image, source: .photoLibrary)
        let stale = presentation.finishDismissal(sessionID: oldID)
        #expect(stale == nil)
        #expect(presentation.session?.id == newID)
        let current = presentation.finishDismissal(sessionID: newID)
        #expect(current?.image.originalData == image.originalData)
    }
}
