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
    let dayDate: Date

    @Environment(\.dismiss) private var dismissSheet

    @StateObject private var addMealViewModel = AddMealViewModel(
        service: BackendMealParsingService(
            baseURL: URL(string: "http://localhost:5001")!
        )
    )

    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var pendingParsed: ParsedMeal?
    @State private var pendingMealTime: Date = Date()
    @State private var pendingDescription: String = "Photo meal"
    @State private var showReview: Bool = false
    @State private var cameraAlert: CameraAlert?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 16) {
                    HStack {
                        Button {
                            dismissSheet()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.headline).bold()
                                .foregroundStyle(Color(.systemGray))
                                .padding(10)
                                .background(Color(.systemBackground), in: Circle())
                                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    VStack(spacing: 12) {
                        if let image = capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 240)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        } else {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.85))
                                .frame(height: 240)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "camera")
                                            .font(.system(size: 28, weight: .semibold))
                                            .foregroundStyle(Color.liftEatsCoral)
                                        Text("Take a meal photo")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("We will estimate macros from your photo.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                        .padding(16)
                                )
                                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                        }

                        Button {
                            openCameraIfAllowed()
                        } label: {
                            Text(capturedImage == nil ? "Open camera" : "Retake photo")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.liftEatsCoral)
                                )
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)

                        if addMealViewModel.isPreparingImage {
                            ProgressView()
                        }

                        if let error = addMealViewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        Button {
                            pendingParsed = nil
                            addMealViewModel.errorMessage = nil
                            pendingMealTime = combine(date: dayDate, time: Date())
                            showReview = true

                            Task {
                                await addMealViewModel.parse()
                                await MainActor.run {
                                    pendingParsed = addMealViewModel.parsed
                                }
                            }
                        } label: {
                            Text("Estimate macros")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(capturedImage == nil || !addMealViewModel.isPhotoReady || addMealViewModel.isLoading ? Color.gray.opacity(0.3) : Color.liftEatsCoral)
                                )
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .disabled(capturedImage == nil || !addMealViewModel.isPhotoReady || addMealViewModel.isLoading)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .sheet(isPresented: $showCamera) {
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
                        ReviewMealImageSheet(
                            image: image,
                            originalDescription: pendingDescription,
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
                        } onReset: {
                            showReview = false
                            pendingParsed = nil
                            capturedImage = nil
                            addMealViewModel.errorMessage = nil
                            addMealViewModel.removeSelectedPhoto()
                        } onDiscard: {
                            showReview = false
                            dismissSheet()
                        }
                    } else {
                        VStack(spacing: 16) {
                            if let error = addMealViewModel.errorMessage {
                                MealParsingErrorView(message: error) {
                                    showReview = false
                                    pendingParsed = nil
                                    addMealViewModel.errorMessage = nil
                                }
                            } else {
                                MealParsingLoadingView()
                            }
                        }
                        .padding()
                    }
                }
            }
            .onChange(of: capturedImage) { _, newImage in
                guard let newImage else {
                    addMealViewModel.removeSelectedPhoto()
                    return
                }

                addMealViewModel.errorMessage = nil
                addMealViewModel.setSelectedPhoto(newImage)
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
            cameraAlert = CameraAlert(
                title: "Camera Access Needed",
                message: "To take meal photos, enable Camera access for LiftEats in Settings.",
                offersSettingsShortcut: true
            )

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
    AddMealCameraFlowSheet(dayLogViewModel: DayLogViewModel(profile: dummyProfile), dayDate: Date())
}
