import Foundation

struct MealPhotoPresentation {
    struct Session: Identifiable {
        let id = UUID()
        let source: MealImageSource
        let loggedAt: Date
    }

    struct Submission {
        let photo: ConfirmedMealPhoto
        let loggedAt: Date
    }

    private(set) var session: Session?
    private(set) var isDismissing = false
    private var confirmedPhoto: ConfirmedMealPhoto?
    var isActive: Bool { session != nil }

    mutating func present(source: MealImageSource, loggedAt: Date) {
        guard !isActive else { return }
        session = Session(source: source, loggedAt: loggedAt)
    }

    mutating func dismiss() {
        guard isActive, !isDismissing else { return }
        isDismissing = true
    }

    mutating func confirm(_ photo: ConfirmedMealPhoto, source: MealImageSource) {
        guard session?.source == source, !isDismissing else { return }
        confirmedPhoto = photo
        isDismissing = true
    }

    mutating func finishDismissal(sessionID: UUID) -> Submission? {
        guard let session, session.id == sessionID, isDismissing else { return nil }
        defer { cancel() }
        guard let confirmedPhoto else { return nil }
        return Submission(photo: confirmedPhoto, loggedAt: session.loggedAt)
    }

    mutating func cancel() {
        self = MealPhotoPresentation()
    }
}
