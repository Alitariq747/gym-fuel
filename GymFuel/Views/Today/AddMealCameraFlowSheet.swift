//
//  AddMealCameraFlowSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 21/02/2026.
//

import AVFoundation
import SwiftUI
import UIKit

struct AddMealCameraFlowSheet: View {
    private struct CameraAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let offersSettingsShortcut: Bool
    }

    @ObservedObject var dayLogViewModel: DayLogViewModel
    @ObservedObject var addMealViewModel: AddMealViewModel
    let dayDate: Date
    let onPermissionDenied: (String) -> Void

    @Environment(\.dismiss) private var dismissSheet

    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var pendingParsed: ParsedMeal?
    @State private var pendingMealTime: Date = Date()
    @State private var showReview: Bool = false
    @State private var cameraAlert: CameraAlert?
    @State private var didStartParse = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
            }
            .fullScreenCover(isPresented: $showCamera, onDismiss: {
                if capturedImage == nil {
                    dismissSheet()
                }
            }) {
                CameraPicker(image: $capturedImage)
            }
            .alert(item: $cameraAlert) { alert in
                if alert.offersSettingsShortcut {
                    Alert(
                        title: Text(alert.title),
                        message: Text(alert.message),
                        primaryButton: .default(Text("Open Settings")) {
                            openAppSettings()
                        },
                        secondaryButton: .cancel(Text("Not Now"))
                    )
                } else {
                    Alert(
                        title: Text(alert.title),
                        message: Text(alert.message),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .navigationDestination(isPresented: $showReview) {
                ZStack {
                    AppBackground()
                    if let parsed = pendingParsed, let image = capturedImage {
                        let description = parsed.name ?? "Photo meal"
                        ReviewMealImageSheet(
                            image: image,
                            originalDescription: description,
                            parsed: parsed,
                            mealTime: pendingMealTime
                        ) { finalDescription, finalParsed, finalTime in
                            Task {
                                await dayLogViewModel.addMealAi(
                                    originalDescription: finalDescription,
                                    parsedMeal: finalParsed,
                                    loggedAt: finalTime
                                )
                            }
                            dismissSheet()
                        } onDiscard: {
                            showReview = false
                            dismissSheet()
                        }
                    } else if let image = capturedImage {
                        VStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.white.opacity(0.85))
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(8)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)

                            if let error = addMealViewModel.errorMessage {
                                MealParsingErrorView(
                                    message: error,
                                    buttonTitle: "Back to photo",
                                    hint: nil,
                                    retryTitle: addMealViewModel.canRetry ? "Retry" : nil,
                                    isRetryDisabled: addMealViewModel.isLoading,
                                    onRetry: addMealViewModel.canRetry ? {
                                        pendingParsed = nil
                                        didStartParse = false
                                        Task {
                                            await addMealViewModel.parse()
                                            await MainActor.run {
                                                pendingParsed = addMealViewModel.parsed
                                            }
                                        }
                                    } : nil
                                ) {
                                    showReview = false
                                    pendingParsed = nil
                                    addMealViewModel.errorMessage = nil
                                }
                            } else {
                                VStack(spacing: 12) {
                                    MealParsingLoadingView()
                                    Text("Estimating macros…")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                    } else {
                        MealParsingLoadingView()
                            .padding()
                    }
                }
                .navigationBarBackButtonHidden(true)
            }
            .onChange(of: capturedImage) { _, newImage in
                guard let newImage else {
                    addMealViewModel.removeSelectedPhoto()
                    return
                }
                didStartParse = false
                addMealViewModel.errorMessage = nil
                addMealViewModel.setSelectedPhoto(newImage)
                pendingParsed = nil
                pendingMealTime = combine(date: dayDate, time: Date())
                showReview = true
            }
            .onChange(of: addMealViewModel.isPhotoReady) { _, ready in
                guard ready, !didStartParse else { return }
                didStartParse = true
                Task {
                    await addMealViewModel.parse()
                    await MainActor.run {
                        pendingParsed = addMealViewModel.parsed
                    }
                }
            }
            .onAppear {
                openCameraIfAllowed()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func combine(date: Date, time: Date) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        let timeComps = cal.dateComponents([.hour, .minute], from: time)
        comps.hour = timeComps.hour
        comps.minute = timeComps.minute
        return cal.date(from: comps) ?? date
    }

    private func openCameraIfAllowed() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            cameraAlert = CameraAlert(
                title: "Camera Unavailable",
                message: "This device doesn't have an available camera.",
                offersSettingsShortcut: false
            )
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCamera = true

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera = true
                    } else {
                        cameraAlert = CameraAlert(
                            title: "Camera Access Needed",
                            message: "To take meal photos, enable Camera access for LiftEats in Settings.",
                            offersSettingsShortcut: true
                        )
                    }
                }
            }

        case .denied, .restricted:
            dismissSheet()
            onPermissionDenied("To use photo logging, enable Camera access for LiftEats in Settings.")

        @unknown default:
            cameraAlert = CameraAlert(
                title: "Camera Error",
                message: "We couldn't access the camera right now. Please try again.",
                offersSettingsShortcut: false
            )
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    AddMealCameraFlowSheet(
        dayLogViewModel: DayLogViewModel(profile: dummyProfile),
        addMealViewModel: AddMealViewModel(
            service: BackendMealParsingService(
                baseURL: URL(string: "http://localhost:5001")!
            )
        ),
        dayDate: Date(),
        onPermissionDenied: { _ in }
    )
}
