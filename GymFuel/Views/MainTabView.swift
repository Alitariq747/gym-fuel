//
//  MainTabView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/12/2025.
//

import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

enum DayNavigationDirection {
    case previous
    case next
}

struct MainTabView: View {
    let profile: UserProfile
    @EnvironmentObject private var profileViewModel: UserProfileViewModel
    @StateObject var composerViewModel = LogComposerViewModel()
    @StateObject private var logEntryDetailViewModel = LogEntryDetailViewModel()
    @StateObject var timelineViewModel = TimelineViewModel()
    @State private var showProfile = false
    @State private var showSavedMeals = false
    @State private var showStats = false
    @State private var showTextLogSheet = false
    @State private var showFutureLoggingToast = false
    @State private var selectedEntry: LogEntry?
    @State var mealImageDraft = MealImageDraft()
    @State var pendingMealImageSource: MealImageSource?
    @State var showCameraCapture = false
    @State private var showCameraPermissionAlert = false
    @State var showPhotoLibraryPicker = false
    @State var selectedPhotoPickerItem: PhotosPickerItem?
    @State private var dayNavigationDirection: DayNavigationDirection = .previous
    @AppStorage("appColorSchemePreference") private var colorSchemePreference = "system"

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private var targetMacros: Macros? {
        profileViewModel.targetMacros
    }

    private var consumedMacros: Macros {
        timelineViewModel.consumedMacros
    }
    private var canLogForSelectedDate: Bool {
        isDateWithinLoggingWindow(timelineViewModel.selectedDate)
    }

    private var canNavigateToNextDate: Bool {
        guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: timelineViewModel.selectedDate) else {
            return false
        }
        return !isFutureDate(nextDay)
    }

    private func isFutureDate(_ date: Date, calendar: Calendar = .current, now: Date = .now) -> Bool {
        calendar.startOfDay(for: date) > calendar.startOfDay(for: now)
    }

    private func isDateWithinLoggingWindow(_ date: Date, calendar: Calendar = .current, now: Date = .now) -> Bool {
        let selectedDay = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: now)
        guard selectedDay <= today else { return false }
        guard let oldestAllowedDay = calendar.date(byAdding: .day, value: -7, to: today) else { return false }
        return selectedDay >= oldestAllowedDay
    }

    private func presentFutureLoggingToast() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            showFutureLoggingToast = true
        }
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeOut(duration: 0.2)) {
                showFutureLoggingToast = false
            }
        }
    }

    private var dayChangeAnimation: Animation {
        .easeInOut(duration: 0.24)
    }

    private var dayContentTransition: AnyTransition {
        switch dayNavigationDirection {
        case .previous:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        case .next:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                MainTabHeaderView(
                    selectedDate: timelineViewModel.selectedDate,
                    loggedDays: timelineViewModel.loggedDaysInVisibleMonth,
                    canNavigateToNextDate: canNavigateToNextDate,
                    navigationDirection: dayNavigationDirection,
                    onPreviousDateTap: {
                        navigateToPreviousDate()
                    },
                    onNextDateTap: {
                        navigateToNextDate()
                    },
                    onStatsTap: {
                        showStats = true
                    },
                    onProfileTap: {
                        showProfile = true
                    }
                )
                ZStack {
                    dayContent
                        .id(timelineViewModel.selectedDate)
                        .transition(dayContentTransition)
                }
                .clipped()
                .animation(dayChangeAnimation, value: timelineViewModel.selectedDate)
            }
            .padding(.horizontal)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if selectedEntry == nil {
                    bottomDock
                        .padding(.horizontal, 16)
                        .padding(.bottom, -10)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showProfile) {
                ProfileView()
                    .preferredColorScheme(preferredColorScheme)
            }
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
                    guard canUseAIFeatures() else { return }

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
        .overlay(alignment: .bottom) {
            if showFutureLoggingToast {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                    Text("Future logging is not allowed")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemBackground).opacity(0.96), in: Capsule())
                .shadow(color: Color.black.opacity(0.12), radius: 14, y: 7)
                .padding(.bottom, 18)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showStats) {
            NavigationStack { StatsView(profile: profile) }
                .preferredColorScheme(preferredColorScheme)
        }
        .sheet(isPresented: $showTextLogSheet) {
            TextEntrySheet(
                text: $composerViewModel.draft.text,
                onClearError: {
                    composerViewModel.clearError()
                },
                onAnalyze: {
                    Task { await submitCurrentDraft() }
                }
            )
            .preferredColorScheme(preferredColorScheme)
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
            .preferredColorScheme(preferredColorScheme)
        }
        .onChange(of: pendingMealImageSource) { _, newValue in
            if newValue != nil {
                dismissComposerKeyboard()
            }
            showCameraCapture = newValue == .camera
            showPhotoLibraryPicker = newValue == .photoLibrary
        }
        .onChange(of: selectedPhotoPickerItem) { _, newValue in
            guard newValue != nil else { return }
            dismissComposerKeyboard()
            mealImageDraft.source = .photoLibrary
            mealImageDraft.state = .preparing
            pendingMealImageSource = nil
            Task {
                await loadSelectedPhotoData()
            }
        }
        .onChange(of: mealImageDraft.state) { _, newValue in
            guard newValue == .readyToAnalyze else { return }
            dismissComposerKeyboard()
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
        .alert("Camera Access Required", isPresented: $showCameraPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                openAppSettings()
            }
        } message: {
            Text("Allow camera access in Settings to capture meal photos for logging.")
        }
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
            await timelineViewModel.loadLoggedDaysInVisibleMonth(
                containing: timelineViewModel.selectedDate,
                userId: profile.id
            )
        }
        .task(id: timelineViewModel.selectedDate) {
            await timelineViewModel.loadLoggedDaysInVisibleMonth(
                containing: timelineViewModel.selectedDate,
                userId: profile.id
            )
        }
        .onChange(of: timelineViewModel.timeline.entries) { _, _ in
            retryFailedMealImageUploadsIfNeeded()
        }
        .onChange(of: composerViewModel.isSubmitting) { _, isSubmitting in
            if isSubmitting {
                dismissComposerKeyboard()
            }
        }
    }

    private func handleUpdatedEntry(_ updatedEntry: LogEntry) async {
        selectedEntry = updatedEntry
    }

    private func navigateToPreviousDate() {
        dayNavigationDirection = .previous
        Task {
            await timelineViewModel.goToPreviousDay(userId: profile.id)
        }
    }

    private func navigateToNextDate() {
        guard canNavigateToNextDate else {
            presentFutureLoggingToast()
            return
        }

        dayNavigationDirection = .next
        Task {
            await timelineViewModel.goToNextDay(userId: profile.id)
        }
    }

    private var dayContent: some View {
        VStack(spacing: 20) {
            if let targetMacros {
                DailyMacroDetailSheet(
                    targetMacros: targetMacros,
                    consumedMacros: consumedMacros,
                    burnedCalories: timelineViewModel.burnedCalories
                )
            }

            Text("Logged Today")
                .font(.title3.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            MainTabTimelineContentView(
                viewModel: timelineViewModel,
                localPreviewData: { entryId in
                    timelineViewModel.localImagePreviewData(for: entryId)
                },
                onSelectEntry: { entry in
                    selectedEntry = entry
                },
                onRetryEntry: { entry in
                    retryFailedEntry(entry)
                },
                onDeleteFailedEntry: { entry in
                    deleteFailedEntry(entry)
                },
                onSuccessRevealCompleted: { entryId in
                    timelineViewModel.markSuccessRevealed(for: entryId)
                },
                bottomContentInset: canLogForSelectedDate ? 118 : 24
            )
            .contentShape(Rectangle())
            .onTapGesture {
                dismissComposerKeyboard()
            }
        }
    }

    private func handleCameraTap() {
        guard canUseAIFeatures() else { return }

        dismissComposerKeyboard()

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied, .restricted:
            pendingMealImageSource = nil
            showCameraCapture = false
            showCameraPermissionAlert = true
        case .authorized:
            pendingMealImageSource = .camera
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted {
                        pendingMealImageSource = .camera
                    } else {
                        pendingMealImageSource = nil
                        showCameraCapture = false
                        showCameraPermissionAlert = true
                    }
                }
            }
        @unknown default:
            pendingMealImageSource = nil
            showCameraCapture = false
            showCameraPermissionAlert = true
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func canUseAIFeatures() -> Bool {
        return true
    }

    func dismissComposerKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    @ViewBuilder
    private var bottomDock: some View {
        if canLogForSelectedDate {
            LogActionDock(
                isSubmitting: composerViewModel.isSubmitting,
                onCameraTap: {
                    handleCameraTap()
                },
                onPhotoTap: {
                    guard canUseAIFeatures() else { return }
                    pendingMealImageSource = .photoLibrary
                },
                onTextTap: {
                    guard canUseAIFeatures() else { return }
                    composerViewModel.clearError()
                    showTextLogSheet = true
                },
                onSavedMealsTap: {
                    composerViewModel.clearError()
                    showSavedMeals = true
                }
            )
        } else {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Color.secondary)
                Text("Logging is available for today and the past 7 days")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(minHeight: 64)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private func retryFailedMealImageUploadsIfNeeded() {
        timelineViewModel.imageUploadRetryCandidates().forEach { entry in
            composerViewModel.retryFailedMealImageUploadIfNeeded(for: entry)
        }
    }

    private func retryFailedEntry(_ entry: LogEntry) {
        Task {
            if entry.source == .image {
                guard let imageData = await imageDataForRetryingMealImage(entryId: entry.id) else { return }
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
    }

    private func deleteFailedEntry(_ entry: LogEntry) {
        Task {
            let didDelete = await logEntryDetailViewModel.deleteEntry(entry)
            if didDelete {
                timelineViewModel.removeLocalImagePreviewData(for: entry.id)
                timelineViewModel.removeLocalPreparedImageData(for: entry.id)
            }
        }
    }

    private func submitCurrentDraft() async {
        dismissComposerKeyboard()
        let goalType = profile.goalType ?? GoalType.defaultValue
        let loggedAt = loggedAtForSelectedDay()
        _ = await composerViewModel.submitText(
            userId: profile.id,
            goal: goalType,
            loggedAt: loggedAt
        )
    }

    func loggedAtForSelectedDay(
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
