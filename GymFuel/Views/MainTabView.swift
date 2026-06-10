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
    @StateObject var composerViewModel = LogComposerViewModel()
    @StateObject private var logEntryDetailViewModel = LogEntryDetailViewModel()
    @StateObject var timelineViewModel = TimelineViewModel()
    @State private var showProfile = false
    @State private var showSavedMeals = false
    @State private var showStats = false
    @State private var showDailyMacroDetails = false
    @State private var showDatePicker = false
    @State private var showFutureLoggingToast = false
    @State private var pickedDate = Date.now
    @State private var selectedEntry: LogEntry?
    @State var mealImageDraft = MealImageDraft()
    @State var pendingMealImageSource: MealImageSource?
    @State var showCameraCapture = false
    @State var showPhotoLibraryPicker = false
    @State var selectedPhotoPickerItem: PhotosPickerItem?
    @FocusState private var isComposerFocused: Bool
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
    private var canSubmitDraft: Bool {
        composerViewModel.draft.hasContent
    }

    private var canLogForSelectedDate: Bool {
        isDateWithinLoggingWindow(timelineViewModel.selectedDate)
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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                MainTabHeaderView(
                    selectedDate: timelineViewModel.selectedDate,
                    onDateTap: {
                        pickedDate = timelineViewModel.selectedDate
                        showDatePicker = true
                    },
                    onStatsTap: {
                        showStats = true
                    },
                    onProfileTap: {
                        showProfile = true
                    }
                )
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
                    }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissComposerKeyboard()
                }

                if canLogForSelectedDate {
                    LogComposerBar(
                        text: $composerViewModel.draft.text,
                        focus: $isComposerFocused,
                        isSubmitting: composerViewModel.isSubmitting,
                        canSubmit: canSubmitDraft,
                        onClearError: {
                            composerViewModel.clearError()
                        },
                        onCameraTap: {
                            dismissComposerKeyboard()
                            pendingMealImageSource = .camera
                        },
                        onPhotoTap: {
                            dismissComposerKeyboard()
                            pendingMealImageSource = .photoLibrary
                        },
                        onSavedMealsTap: {
                            dismissComposerKeyboard()
                            composerViewModel.clearError()
                            showSavedMeals = true
                        },
                        onSubmit: {
                            dismissComposerKeyboard()
                            Task { await submitCurrentDraft() }
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
        .sheet(isPresented: $showProfile) {
            NavigationStack { ProfileView() }
                .preferredColorScheme(preferredColorScheme)
        }
        .sheet(isPresented: $showStats) {
            NavigationStack { StatsView(profile: profile) }
                .preferredColorScheme(preferredColorScheme)
        }
        .sheet(isPresented: $showDailyMacroDetails) {
            if let targetMacros {
                DailyMacroDetailSheet(
                    targetMacros: targetMacros,
                    consumedMacros: consumedMacros,
                    burnedCalories: timelineViewModel.burnedCalories
                )
                .preferredColorScheme(preferredColorScheme)
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
            .preferredColorScheme(preferredColorScheme)
        }
        .sheet(isPresented: $showDatePicker) {
            LoggedMonthCalendarView(
                visibleMonth: pickedDate,
                selectedDate: timelineViewModel.selectedDate,
                loggedDays: timelineViewModel.loggedDaysInVisibleMonth,
                onPreviousMonth: {
                    pickedDate = Calendar.current.date(byAdding: .month, value: -1, to: pickedDate) ?? pickedDate
                },
                onNextMonth: {
                    pickedDate = Calendar.current.date(byAdding: .month, value: 1, to: pickedDate) ?? pickedDate
                },
                onSelectDate: { date in
                    guard !isFutureDate(date) else {
                        showDatePicker = false
                        presentFutureLoggingToast()
                        return
                    }

                    Task {
                        await timelineViewModel.setSelectedDate(date, userId: profile.id)
                        showDatePicker = false
                    }
                },
                onSelectFutureDate: {
                    showDatePicker = false
                    presentFutureLoggingToast()
                }
            )
            .padding()
            .preferredColorScheme(preferredColorScheme)
            .task(id: pickedDate) {
                await timelineViewModel.loadLoggedDaysInVisibleMonth(
                    containing: pickedDate,
                    userId: profile.id
                )
            }
            .presentationDetents([.medium])
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

    func dismissComposerKeyboard() {
        isComposerFocused = false
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
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
