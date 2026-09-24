import AVFoundation
import Foundation

struct MealCameraStatus: Equatable, Sendable {
    enum Phase: Equatable, Sendable {
        case starting, ready, capturing
        case failed(String)
    }
    var phase: Phase = .starting
    var isFrontCamera = false
    var canSwitchCamera = false
    var supportsFlash = false
    var flashEnabled = false
}

// All mutable capture state is confined to queue. Only the preview layer reads
// session on the main thread; it never configures or starts/stops the session.
final class MealCameraService: NSObject, @unchecked Sendable {
    private static let captureQueue = DispatchQueue(label: "circa.meal-camera", qos: .userInitiated)
    let session = AVCaptureSession()
    let queue = MealCameraService.captureQueue
    let output = AVCapturePhotoOutput()
    var input: AVCaptureDeviceInput?
    var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    var status = MealCameraStatus()
    var wantsRunning = false
    var captureID: Int64?
    var photoData: Data?
    var observers: [NSObjectProtocol] = []
    let onStatus: @Sendable (MealCameraStatus) -> Void
    let onPhoto: @Sendable (Data) -> Void

    init(
        onStatus: @escaping @Sendable (MealCameraStatus) -> Void,
        onPhoto: @escaping @Sendable (Data) -> Void
    ) {
        self.onStatus = onStatus
        self.onPhoto = onPhoto
        super.init()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    func start() {
        queue.async { self.startSession() }
    }

    func stop() {
        queue.async {
            self.wantsRunning = false
            self.captureID = nil
            self.photoData = nil
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    func startSession() {
        wantsRunning = true
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            fail("Camera access is unavailable. You can enable it in Settings.")
            return
        }
        status.phase = .starting
        onStatus(status)
        do {
            if input == nil { try configure() }
            if !session.isRunning { session.startRunning() }
            guard session.isRunning, !session.isInterrupted else {
                fail("The camera is temporarily unavailable. Please try again.")
                return
            }
            refreshControls()
            status.phase = .ready
            onStatus(status)
        } catch {
            fail("We couldn't start the camera. Please try again.")
        }
    }

    private func configure() throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw MealImagePreparationError.invalidImageData
        }
        let newInput = try AVCaptureDeviceInput(device: device)
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .photo
        guard session.canAddInput(newInput) else { throw MealImagePreparationError.invalidImageData }
        session.addInput(newInput)
        guard session.canAddOutput(output) else {
            session.removeInput(newInput)
            throw MealImagePreparationError.invalidImageData
        }
        session.addOutput(output)
        input = newInput
        observeSession()
    }

    func capture() {
        queue.async {
            guard self.wantsRunning, self.status.phase == .ready, self.captureID == nil else { return }
            guard self.session.isRunning, !self.session.isInterrupted else {
                self.fail("The camera is temporarily unavailable. Please try again.")
                return
            }
            let settings = AVCapturePhotoSettings()
            let flash: AVCaptureDevice.FlashMode = self.status.flashEnabled ? .on : .off
            if self.output.supportedFlashModes.contains(flash) { settings.flashMode = flash }
            if let connection = self.output.connection(with: .video) {
                let angle = self.rotationCoordinator?.videoRotationAngleForHorizonLevelCapture ?? 90
                if connection.isVideoRotationAngleSupported(angle) { connection.videoRotationAngle = angle }
                if connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = self.status.isFrontCamera
                }
            }
            self.captureID = settings.uniqueID
            self.photoData = nil
            self.status.phase = .capturing
            self.onStatus(self.status)
            self.output.capturePhoto(with: settings, delegate: self)
        }
    }

    func fail(_ message: String) {
        status.phase = .failed(message)
        onStatus(status)
    }
}

extension MealCameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let id = photo.resolvedSettings.uniqueID
        let data = error == nil ? photo.fileDataRepresentation() : nil
        queue.async {
            guard self.captureID == id else { return }
            self.photoData = data
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        let id = resolvedSettings.uniqueID
        let succeeded = error == nil
        queue.async {
            guard self.captureID == id, self.wantsRunning else { return }
            self.captureID = nil
            guard succeeded, let data = self.photoData else {
                self.fail("We couldn't take that photo. Please try again.")
                return
            }
            self.photoData = nil
            self.wantsRunning = false
            self.session.stopRunning()
            self.onPhoto(data)
        }
    }
}
