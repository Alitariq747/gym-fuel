//
//  MainTabView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import PhotosUI
import SwiftUI
import UIKit

struct MainTabView: View {
    let profile: UserProfile
    @EnvironmentObject private var profileViewModel: UserProfileViewModel
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var composerViewModel = LogComposerViewModel()
    @StateObject private var logEntryDetailViewModel = LogEntryDetailViewModel()
    @StateObject private var timelineViewModel = TimelineViewModel()
    private let mealImagePreparationService = MealImagePreparationService()
    @State private var showProfile = false
    @State private var showSavedMeals = false
    @State private var showStats = false
    @State private var showDailyMacroDetails = false
    @State private var showDatePicker = false
    @State private var pickedDate = Date.now
    @State private var selectedEntry: LogEntry?
    @State private var mealImageDraft = MealImageDraft()
    @State private var pendingMealImageSource: MealImageSource?
    @State private var showCameraCapture = false
    @State private var showPhotoLibraryPicker = false
    @State private var selectedPhotoPickerItem: PhotosPickerItem?
    @FocusState private var isComposerFocused: Bool
    private var targetMacros: Macros? {
        profileViewModel.targetMacros
    }

    private var topChipBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }

    private var topChipStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear
    }

    private var topChipShadow: Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.08)
    }

    private var consumedMacros: Macros {
        timelineViewModel.consumedMacros
    }
    private var canSubmitDraft: Bool {
        composerViewModel.draft.hasContent
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack {
                    Image("LiftEatsWelcomeIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                        .frame(width: 76, alignment: .leading)

                    Spacer()

                    Button {
                        pickedDate = timelineViewModel.selectedDate
                        showDatePicker = true
                    } label: {
                        Text(timelineViewModel.selectedDate.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(topChipBackground, in: Capsule())
                            .overlay(Capsule().stroke(topChipStroke, lineWidth: 1))
                            .shadow(color: topChipShadow, radius: 10, y: 4)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    HStack(spacing: 14) {
                        Button { showStats = true } label: {
                            Image(systemName: "flame.fill")
                                .frame(width: 18, height: 18)
                                .foregroundStyle(Color.fuelOrange)
                        }
                        .buttonStyle(.plain)

                        Button { showProfile = true } label: {
                            Image(systemName: "gearshape")
                                .frame(width: 18, height: 18)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(topChipBackground, in: Capsule())
                    .overlay(Capsule().stroke(topChipStroke, lineWidth: 1))
                    .shadow(color: topChipShadow, radius: 10, y: 4)
                    .frame(width: 76, alignment: .trailing)
                }
                if let targetMacros {
                    DailyMacroSummaryView(
                        targetMacros: targetMacros,
                        consumedMacros: consumedMacros,
                        burnedCalories: timelineViewModel.burnedCalories,
                        onTap: {
                            showDailyMacroDetails = true
                        }
                    )
                }

                Group {
                    if timelineViewModel.isLoading {
                        ProgressView("Loading timeline...")
                    } else if let errorMessage = timelineViewModel.errorMessage {
                        VStack(spacing: 8) {
                            Text("Failed to load timeline")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    } else if !timelineViewModel.timeline.entries.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(timelineViewModel.timeline.entries) { entry in
                                    let retryAction: (() -> Void)? = entry.status == .failed ? {
                                        Task {
                                            if entry.source == .image,
                                               let imageData = timelineViewModel.localPreparedImageData(for: entry.id) {
                                                _ = await composerViewModel.retryMealImageEntry(
                                                    entry,
                                                    imageData: imageData,
                                                    goal: profile.goalType ?? GoalType.defaultValue
                                                )
                                            } else {
                                                _ = await composerViewModel.retryTextEntry(
                                                    entry,
                                                    goal: profile.goalType ?? GoalType.defaultValue
                                                )
                                            }
                                        }
                                    } : nil
                                    let deleteAction: (() -> Void)? = entry.status == .failed ? {
                                        Task {
                                            let didDelete = await logEntryDetailViewModel.deleteEntry(entry)
                                            if didDelete {
                                                timelineViewModel.removeLocalImagePreviewData(for: entry.id)
                                                timelineViewModel.removeLocalPreparedImageData(for: entry.id)
                                            }
                                        }
                                    } : nil
                                    let shouldAnimateSuccessReveal = entry.status == .succeeded && !timelineViewModel.hasRevealedSuccess(for: entry.id)
                                    let successRevealCompleted: (() -> Void)? = shouldAnimateSuccessReveal ? {
                                        timelineViewModel.markSuccessRevealed(for: entry.id)
                                    } : nil
                                    Button {
                                        selectedEntry = entry
                                    } label: {
                                        TimelineEntryRow(
                                            entry: entry,
                                            localPreviewData: timelineViewModel.localImagePreviewData(for: entry.id),
                                            onRetry: retryAction,
                                            onDelete: deleteAction,
                                            shouldAnimateSuccessReveal: shouldAnimateSuccessReveal,
                                            onSuccessRevealCompleted: successRevealCompleted
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    } else if timelineViewModel.timeline.entries.isEmpty {
                        Color.clear
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .contentShape(Rectangle())
                .onTapGesture {
                    isComposerFocused = false
                }

                LogComposerBar(
                    text: $composerViewModel.draft.text,
                    focus: $isComposerFocused,
                    isSubmitting: composerViewModel.isSubmitting,
                    canSubmit: canSubmitDraft,
                    onClearError: {
                        composerViewModel.clearError()
                    },
                    onCameraTap: {
                        pendingMealImageSource = .camera
                    },
                    onPhotoTap: {
                        pendingMealImageSource = .photoLibrary
                    },
                    onSavedMealsTap: {
                        composerViewModel.clearError()
                        showSavedMeals = true
                    },
                    onSubmit: {
                        Task { await submitCurrentDraft() }
                    }
                )
            }
            .padding(.horizontal)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedEntry) { entry in
            LogEntryDetailSheet(
                entry: entry,
                isPerformingAction: logEntryDetailViewModel.isSaving,
                aiErrorMessage: logEntryDetailViewModel.aiErrorMessage,
                actionErrorMessage: logEntryDetailViewModel.actionErrorMessage,
                onClearAIError: {
                    logEntryDetailViewModel.clearAIError()
                },
                onClearActionError: {
                    logEntryDetailViewModel.clearActionError()
                },
                onSaveMacros: { macros in
                    Task {
                        if let updatedEntry = await logEntryDetailViewModel.updateMacros(for: entry, to: macros) {
                                await handleUpdatedEntry(updatedEntry)
                            }
                        }
                    },
                onSaveCaloriesBurned: { caloriesBurned in
                    Task {
                        if let updatedEntry = await logEntryDetailViewModel.updateCaloriesBurned(
                            for: entry,
                            to: caloriesBurned
                            ) {
                                await handleUpdatedEntry(updatedEntry)
                        }
                    }
                },
                onSaveLoggedAt: { loggedAt in
                    Task {
                        if let updatedEntry = await logEntryDetailViewModel.updateLoggedAt(for: entry, to: loggedAt) {
                            await handleUpdatedEntry(updatedEntry)
                        }
                    }
                },
                onDeleteEntry: {
                    Task {
                        let didDelete = await logEntryDetailViewModel.deleteEntry(entry)
                        if didDelete {
                            selectedEntry = nil
                        }
                    }
                },
                onUseAIAgain: { editedText in
                    Task {
                        let goalType = profile.goalType ?? GoalType.defaultValue
                        if let updatedEntry = await logEntryDetailViewModel.reinterpretEntry(
                            entry,
                            newRawInput: editedText,
                            goal: goalType
                        ) {
                            await handleUpdatedEntry(updatedEntry)
                        }
                    }
                }
            )
        }
        }
        .sheet(isPresented: $showProfile) {
            NavigationStack { ProfileView() }
        }
        .sheet(isPresented: $showStats) {
            NavigationStack { StatsView(profile: profile) }
        }
        .sheet(isPresented: $showDailyMacroDetails) {
            if let targetMacros {
                DailyMacroDetailSheet(
                    targetMacros: targetMacros,
                    consumedMacros: consumedMacros,
                    burnedCalories: timelineViewModel.burnedCalories
                )
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.hidden)
            }
        }
        .sheet(isPresented: $showSavedMeals) {
            SavedMealsPickerSheet(userId: profile.id) { meal in
                Task {
                    let didSave = await composerViewModel.logSavedMeal(
                        meal,
                        userId: profile.id,
                        loggedAt: loggedAtForSelectedDay()
                    )
                    if didSave {
                        showSavedMeals = false
                    }
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $pickedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
            }
            .padding()
            .onChange(of: pickedDate) { _, newValue in
                Task {
                    await timelineViewModel.setSelectedDate(newValue, userId: profile.id)
                    showDatePicker = false
                }
            }
            .presentationDetents([.medium])
        }
        .onChange(of: pendingMealImageSource) { _, newValue in
            showCameraCapture = newValue == .camera
            showPhotoLibraryPicker = newValue == .photoLibrary
        }
        .onChange(of: selectedPhotoPickerItem) { _, newValue in
            guard newValue != nil else { return }
            mealImageDraft.source = .photoLibrary
            mealImageDraft.state = .preparing
            pendingMealImageSource = nil
            Task {
                await loadSelectedPhotoData()
            }
        }
        .onChange(of: mealImageDraft.state) { _, newValue in
            guard newValue == .readyToAnalyze else { return }
            Task {
                await analyzePreparedMealImage()
            }
        }
        .photosPicker(
            isPresented: $showPhotoLibraryPicker,
            selection: $selectedPhotoPickerItem,
            matching: .images,
            preferredItemEncoding: .current
        )
        .fullScreenCover(isPresented: $showCameraCapture) {
            MealCameraCaptureView(
                onImagePicked: { image in
                    handleCapturedMealImage(image)
                },
                onCancel: {
                    showCameraCapture = false
                    pendingMealImageSource = nil
                }
            )
            .ignoresSafeArea()
        }
        .task(id: profile.id) {
            await timelineViewModel.loadTimeline(
                for: timelineViewModel.selectedDate,
                userId: profile.id
            )
        }
    }

    private func handleUpdatedEntry(_ updatedEntry: LogEntry) async {
        selectedEntry = updatedEntry
    }

    private func submitCurrentDraft() async {
        let goalType = profile.goalType ?? GoalType.defaultValue
        let loggedAt = loggedAtForSelectedDay()
        _ = await composerViewModel.submitText(
            userId: profile.id,
            goal: goalType,
            loggedAt: loggedAt
        )
    }

    private func loadSelectedPhotoData() async {
        guard let selectedPhotoPickerItem else { return }

        do {
            let imageData = try await selectedPhotoPickerItem.loadTransferable(type: Data.self)
            guard let imageData else {
                mealImageDraft.state = .failed("We couldn't load that photo. Please try another image.")
                return
            }

            let preparedImage = try mealImagePreparationService.prepareImageData(from: imageData)
            mealImageDraft.originalData = preparedImage.originalData
            mealImageDraft.compressedJPEGData = preparedImage.compressedJPEGData
            mealImageDraft.state = .readyToAnalyze
        } catch {
            mealImageDraft.state = .failed(AppErrorMessage.message(
                for: error,
                fallback: "We couldn't prepare that photo. Please try a different image."
            ))
        }
    }

    private func handleCapturedMealImage(_ image: UIImage) {
        showCameraCapture = false
        pendingMealImageSource = nil

        guard let imageData = image.jpegData(compressionQuality: 1) else {
            mealImageDraft.state = .failed("We couldn't capture that photo. Please try again.")
            return
        }

        mealImageDraft.source = .camera
        mealImageDraft.state = .preparing
        Task {
            await prepareCapturedMealImageData(imageData)
        }
    }

    private func prepareCapturedMealImageData(_ imageData: Data) async {
        do {
            let preparedImage = try mealImagePreparationService.prepareImageData(from: imageData)
            mealImageDraft.originalData = preparedImage.originalData
            mealImageDraft.compressedJPEGData = preparedImage.compressedJPEGData
            mealImageDraft.state = .readyToAnalyze
        } catch {
            mealImageDraft.state = .failed(AppErrorMessage.message(
                for: error,
                fallback: "We couldn't prepare that photo. Please try a different image."
            ))
        }
    }

    private func analyzePreparedMealImage() async {
        guard mealImageDraft.isReadyToSubmit,
              let imageData = mealImageDraft.compressedJPEGData else {
            mealImageDraft.state = .failed("We couldn't prepare that photo. Please try a different image.")
            return
        }

        let goalType = profile.goalType ?? GoalType.defaultValue
        let entryId = UUID().uuidString
        if let previewData = mealImageDraft.previewData {
            timelineViewModel.setLocalImagePreviewData(previewData, for: entryId)
        }
        timelineViewModel.setLocalPreparedImageData(imageData, for: entryId)
        let savedEntry = await composerViewModel.submitMealImage(
            imageData,
            userId: profile.id,
            goal: goalType,
            loggedAt: loggedAtForSelectedDay(),
            entryId: entryId
        )

        if savedEntry != nil {
            timelineViewModel.removeLocalImagePreviewData(for: entryId)
            mealImageDraft.reset()
            selectedPhotoPickerItem = nil
        } else {
            // The failed listener row is now the visible source of truth.
        }
    }

    private func loggedAtForSelectedDay(
        calendar: Calendar = .current,
        now: Date = .now
    ) -> Date {
        if calendar.isDate(timelineViewModel.selectedDate, inSameDayAs: now) {
            return now
        }

        let dayComponents = calendar.dateComponents([.year, .month, .day], from: timelineViewModel.selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: now)

        return calendar.date(
            from: DateComponents(
                year: dayComponents.year,
                month: dayComponents.month,
                day: dayComponents.day,
                hour: timeComponents.hour,
                minute: timeComponents.minute,
                second: timeComponents.second,
                nanosecond: timeComponents.nanosecond
            )
        ) ?? now
    }

}

#Preview {
    let auth = FirebaseAuthManager()
    let profileVM = UserProfileViewModel()
    let savedMealsVM = SavedMealsViewModel()
    profileVM._setProfileForPreview(dummyProfile)

    return MainTabView(profile: dummyProfile)
        .environmentObject(auth)
        .environmentObject(profileVM)
        .environmentObject(savedMealsVM)
}
