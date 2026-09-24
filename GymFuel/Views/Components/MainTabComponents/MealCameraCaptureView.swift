import AVFoundation
import SwiftUI

struct MealCameraCaptureView: View {
    let isDismissing: Bool
    let onClose: () -> Void
    let onDismissed: () -> Void
    let onUsePhoto: (PreparedMealImage, MealImageSource) -> Void
    @StateObject private var review = MealPhotoReviewModel(source: .camera)
    @StateObject private var camera = MealCameraModel()
    @State private var isVisible = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    var body: some View {
        MealPhotoPanel(
            isReviewing: review.isReviewing, isDismissing: isDismissing,
            onClose: close, onDismissed: onDismissed
        ) {
            ZStack {
                if review.isReviewing {
                    MealPhotoReviewView(model: review, onReplace: {
                        camera.clearCapture()
                        review.clearSelection()
                    }, onUsePhoto: { image in
                        onUsePhoto(image, .camera)
                    })
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.97)))
                } else {
                    cameraContent.transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: reduceMotion ? 0.15 : 0.25), value: review.isReviewing)
        }
        .onAppear { isVisible = true; updateCameraActivity() }
        .onChange(of: scenePhase) { _, _ in updateCameraActivity() }
        .onChange(of: review.isReviewing) { _, _ in updateCameraActivity() }
        .onChange(of: isDismissing) { _, closing in
            updateCameraActivity()
            if closing { review.cancelPendingWork() }
        }
        .onChange(of: camera.capturedData) { _, data in
            guard isVisible, !isDismissing, let data else { return }
            review.select(data: data)
        }
        .onDisappear {
            isVisible = false
            camera.setActive(false)
            review.clearSelection()
        }
    }

    private var cameraContent: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Color(white: 0.12)
                if let session = camera.session {
                    MealCameraPreview(session: session, isFrontCamera: camera.status.isFrontCamera)
                        .accessibilityLabel("Live camera preview")
                }
                if camera.status.phase != .ready {
                    Color.black.opacity(camera.status.phase == .capturing ? 0.25 : 0.7)
                    AdaptiveScrollContainer {
                        VStack(spacing: 8) {
                            if case .failed(let message) = camera.status.phase {
                                Text(message)
                                    .font(.circaBody)
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                                Button("Retry") { camera.retry() }
                                    .buttonStyle(.bordered)
                                    .frame(minHeight: Circa.minHitTarget)
                                if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
                                    Button("Open Settings") {
                                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                                    }
                                    .buttonStyle(.bordered)
                                    .frame(minHeight: Circa.minHitTarget)
                                }
                            } else {
                                ProgressView(camera.status.phase == .capturing ? "Taking photo…" : "Starting camera…")
                                    .font(.circaCaption)
                            }
                        }
                    }
                    .foregroundStyle(.white)
                    .tint(.white)
                    .padding(24)
                    .padding(.bottom, 104)
                }
            }
            LinearGradient(colors: [.clear, .black.opacity(0.45)], startPoint: .top, endPoint: .bottom)
                .frame(height: 140)
                .allowsHitTesting(false)
            HStack {
                Button(action: close) {
                    MealPhotoControlLabel(symbol: "chevron.backward")
                }
                .accessibilityLabel("Back")
                Spacer()
                Button(action: camera.capture) {
                    Circle().fill(.white)
                        .padding(7)
                        .background(Circle().fill(.black.opacity(0.25)))
                        .overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: 1))
                        .frame(width: 80, height: 80)
                }
                .accessibilityLabel("Take photo")
                .disabled(camera.status.phase != .ready)
                Spacer()
                Menu {
                    Button(action: camera.toggleFlash) {
                        Label(camera.status.flashEnabled ? "Turn flash off" : "Turn flash on",
                              systemImage: camera.status.flashEnabled ? "bolt.slash" : "bolt.fill")
                    }
                    .disabled(!camera.status.supportsFlash)
                    Button(action: camera.switchCamera) {
                        Label(camera.status.isFrontCamera ? "Use rear camera" : "Use front camera",
                              systemImage: "arrow.triangle.2.circlepath.camera")
                    }
                    .disabled(!camera.status.canSwitchCamera)
                } label: {
                    MealPhotoControlLabel(symbol: "ellipsis")
                }
                .accessibilityLabel("More camera options")
                .disabled(camera.status.phase != .ready)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }

    private func updateCameraActivity() {
        camera.setActive(isVisible && !isDismissing && scenePhase == .active && !review.isReviewing)
    }

    private func close() {
        isVisible = false
        camera.setActive(false)
        review.cancelPendingWork()
        onClose()
    }
}
