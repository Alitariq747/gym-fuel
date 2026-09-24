import AVFoundation
import Combine
import Foundation

@MainActor
final class MealCameraModel: ObservableObject {
    @Published private(set) var status = MealCameraStatus()
    @Published private(set) var capturedData: Data?
    private var isActive = false
    private var service: MealCameraService?

    var session: AVCaptureSession? { service?.session }

    func setActive(_ active: Bool) {
        guard active != isActive else { return }
        isActive = active
        if active {
            startNewSession()
        } else {
            service?.stop()
            service = nil
            status = MealCameraStatus()
        }
    }

    func retry() {
        guard isActive else { return }
        service?.stop()
        startNewSession()
    }

    func capture() {
        guard isActive, status.phase == .ready else { return }
        status.phase = .capturing
        service?.capture()
    }

    func switchCamera() { service?.switchCamera() }
    func toggleFlash() { service?.toggleFlash() }
    func clearCapture() { capturedData = nil }

    private var generation = UUID()

    private func startNewSession() {
        generation = UUID()
        let request = generation
        status = MealCameraStatus()
        let service = MealCameraService(onStatus: { [weak self] status in
            Task { @MainActor in
                guard let self, self.isActive, self.generation == request else { return }
                self.status = status
            }
        }, onPhoto: { [weak self] data in
            Task { @MainActor in
                guard let self, self.isActive, self.generation == request else { return }
                self.capturedData = data
                self.setActive(false)
            }
        })
        self.service = service
        service.start()
    }
}
