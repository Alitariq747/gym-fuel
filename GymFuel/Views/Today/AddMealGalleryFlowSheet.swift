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
    let dayDate: Date

    @Environment(\.dismiss) private var dismissSheet

    @StateObject private var addMealViewModel = AddMealViewModel(
        service: BackendMealParsingService(
            baseURL: URL(string: "http://localhost:5001")!
        )
    )

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var pendingParsed: ParsedMeal?
    @State private var pendingMealTime: Date = Date()
    @State private var pendingDescription: String = "Photo meal"
    @State private var showReview: Bool = false
    @State private var selectionError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 16) {
                    HStack {
                        Button {
                            addMealViewModel.reset()
                            selectedItem = nil
                            selectedImage = nil
                            selectionError = nil
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
                        if let image = selectedImage {
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
                                        Image(systemName: "photo.on.rectangle")
                                            .font(.system(size: 28, weight: .semibold))
                                            .foregroundStyle(Color.liftEatsCoral)
                                        Text("Pick a meal photo")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("We will estimate macros based on this image.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                        .padding(16)
                                )
                                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                        }

                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Text(selectedImage == nil ? "Choose from gallery" : "Choose a different photo")
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

                        if let error = selectionError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

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
                                        .fill(selectedImage == nil || !addMealViewModel.isPhotoReady || addMealViewModel.isLoading ? Color.gray.opacity(0.3) : Color.liftEatsCoral)
                                )
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .disabled(selectedImage == nil || !addMealViewModel.isPhotoReady || addMealViewModel.isLoading)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationDestination(isPresented: $showReview) {
                ZStack {
                    AppBackground()
                    if let parsed = pendingParsed, let image = selectedImage {
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
                            selectedItem = nil
                            selectedImage = nil
                            selectionError = nil
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
            .navigationBarBackButtonHidden(true)
        }
        .toolbar(.hidden, for: .navigationBar)
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
                            addMealViewModel.setSelectedPhoto(image)
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
    AddMealGalleryFlowSheet(dayLogViewModel: DayLogViewModel(profile: dummyProfile), dayDate: Date())
}
