import UIKit

@MainActor
protocol HapticFeedbackProviding {
    func notifySuccess()
}

@MainActor
struct HapticFeedbackService: HapticFeedbackProviding {
    func notifySuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}
