//
//  AddMealGalleryFlowSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 21/02/2026.
//

import PhotosUI
import SwiftUI

struct AddMealGalleryFlowSheet: View {
    @ObservedObject var dayLogViewModel: DayLogViewModel
    @ObservedObject var addMealViewModel: AddMealViewModel
    let dayDate: Date

    @Environment(\.dismiss) private var dismissSheet

    @State private var selectedItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var selectedImage: UIImage?
    @State private var pendingParsed: ParsedMeal?
    @State private var pendingMealTime: Date = Date()
    @State private var showReview: Bool = false
    @State private var selectionError: String?
    @State private var didStartParse = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
            }
            .navigationDestination(isPresented: $showReview) {
                ZStack {
                    AppBackground()
                    if let parsed = pendingParsed, let image = selectedImage {
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
                    } else if let image = selectedImage {
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
            .navigationBarBackButtonHidden(true)
        }
        .toolbar(.hidden, for: .navigationBar)
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else {
                selectedImage = nil
                addMealViewModel.removeSelectedPhoto()
                return
            }

            Task {
                do {
                    if let data = try await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = image
                            selectionError = nil
                            addMealViewModel.errorMessage = nil
                            didStartParse = false
                            addMealViewModel.setSelectedPhoto(image)
                            pendingParsed = nil
                            pendingMealTime = combine(date: dayDate, time: Date())
                            showReview = true
                        }
                    } else {
                        await MainActor.run {
                            selectedImage = nil
                            selectionError = "Couldn't load that photo. Please try another."
                            addMealViewModel.errorMessage = nil
                        }
                    }
                } catch {
                    await MainActor.run {
                        selectedImage = nil
                        selectionError = error.localizedDescription
                        addMealViewModel.errorMessage = nil
                    }
                }
            }
        }
        .onChange(of: showPhotoPicker) { _, isPresented in
            if !isPresented && selectedItem == nil {
                dismissSheet()
            }
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
            showPhotoPicker = true
        }
    }

    private func combine(date: Date, time: Date) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        let timeComps = cal.dateComponents([.hour, .minute], from: time)
        comps.hour = timeComps.hour
        comps.minute = timeComps.minute
        return cal.date(from: comps) ?? date
    }
}

#Preview {
    AddMealGalleryFlowSheet(
        dayLogViewModel: DayLogViewModel(profile: dummyProfile),
        addMealViewModel: AddMealViewModel(
            service: BackendMealParsingService(
                baseURL: URL(string: "http://localhost:5001")!
            )
        ),
        dayDate: Date()
    )
}
