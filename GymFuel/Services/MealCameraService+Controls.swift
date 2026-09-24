import AVFoundation
import Foundation

extension MealCameraService {
    func switchCamera() {
        queue.async {
            guard self.wantsRunning, self.status.phase == .ready,
                  let previousInput = self.input, self.status.canSwitchCamera else { return }
            let position: AVCaptureDevice.Position = self.status.isFrontCamera ? .back : .front
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else { return }
            do {
                let replacement = try AVCaptureDeviceInput(device: device)
                self.session.beginConfiguration()
                self.session.removeInput(previousInput)
                if self.session.canAddInput(replacement) {
                    self.session.addInput(replacement)
                    self.input = replacement
                } else {
                    self.session.addInput(previousInput)
                }
                self.session.commitConfiguration()
                self.status.flashEnabled = false
                self.refreshControls()
                self.onStatus(self.status)
            } catch {
                self.fail("We couldn't switch cameras. Please try again.")
            }
        }
    }

    func toggleFlash() {
        queue.async {
            guard self.status.phase == .ready, self.status.supportsFlash else { return }
            self.status.flashEnabled.toggle()
            self.onStatus(self.status)
        }
    }

    func refreshControls() {
        guard let device = input?.device else { return }
        rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: nil)
        status.isFrontCamera = device.position == .front
        let otherPosition: AVCaptureDevice.Position = status.isFrontCamera ? .back : .front
        status.canSwitchCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: otherPosition) != nil
        status.supportsFlash = device.hasFlash && output.supportedFlashModes.contains(.on)
        if !status.supportsFlash { status.flashEnabled = false }
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
            if device.isExposureModeSupported(.continuousAutoExposure) { device.exposureMode = .continuousAutoExposure }
            device.unlockForConfiguration()
        } catch { /* Keep the device's existing automatic settings. */ }
    }

    func observeSession() {
        let names: [Notification.Name] = [
            AVCaptureSession.wasInterruptedNotification,
            AVCaptureSession.interruptionEndedNotification,
            AVCaptureSession.runtimeErrorNotification
        ]
        observers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: session, queue: nil) { [weak self] _ in
                guard let self else { return }
                self.queue.async {
                    guard self.wantsRunning else { return }
                    self.captureID = nil
                    self.photoData = nil
                    if name == AVCaptureSession.interruptionEndedNotification {
                        self.startSession()
                    } else {
                        self.fail("The camera was interrupted. Please try again when it's available.")
                    }
                }
            }
        }
    }
}
