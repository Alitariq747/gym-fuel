import SwiftUI

struct ProfileReminderSection: View {
    let preferredColorScheme: ColorScheme?

    @AppStorage(ReminderMode.preferenceKey) private var reminderModeValue = ReminderMode.quiet.rawValue

    @State private var showPreferences = false
    @State private var isUpdatingMode = false
    @State private var modeBeingApplied: ReminderMode?
    @State private var errorMessage: String?
    @State private var showError = false

    private var selectedMode: ReminderMode {
        ReminderMode(rawValue: reminderModeValue) ?? .quiet
    }

    var body: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "Reminders", systemImage: "bell.badge")

            Button {
                showPreferences = true
            } label: {
                ProfileSettingsRow(
                    title: "Logging Reminders",
                    systemImage: "bell.badge.fill",
                    value: selectedMode.displayName,
                    tint: .liftEatsCoral
                )
            }
            .buttonStyle(.plain)
            .background(ProfileCardBackground())
        }
        .padding(.horizontal)
        .sheet(isPresented: $showPreferences) {
            preferenceSheet
                .preferredColorScheme(preferredColorScheme)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(34)
        }
        .alert("Reminders unavailable", isPresented: $showError) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "LiftEats could not update your reminder preference.")
        }
    }

    private var preferenceSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()

                Button {
                    showPreferences = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(Color(.secondarySystemBackground), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(isUpdatingMode)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(spacing: 7) {
                        Text("Stay consistent, your way")
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.center)

                        Text("Choose how often LiftEats reminds you to log meals or workouts.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16)

                    VStack(spacing: 10) {
                        ForEach(ReminderMode.allCases) { mode in
                            modeButton(mode)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemBackground))
    }

    private func modeButton(_ mode: ReminderMode) -> some View {
        let isSelected = selectedMode == mode
        let tint = tint(for: mode)

        return Button {
            Task { await select(mode) }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol(for: mode))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(tint.opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(mode.displayName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(mode.scheduleDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if modeBeingApplied == mode {
                    ProgressView()
                        .controlSize(.small)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.liftEatsCoral)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.liftEatsCoral : Color.primary.opacity(0.06), lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isUpdatingMode)
    }

    @MainActor
    private func select(_ mode: ReminderMode) async {
        guard mode != selectedMode, !isUpdatingMode else { return }

        isUpdatingMode = true
        modeBeingApplied = mode
        defer {
            isUpdatingMode = false
            modeBeingApplied = nil
        }

        do {
            try await ReminderService.shared.apply(mode)
            reminderModeValue = mode.rawValue
        } catch {
            reminderModeValue = ReminderMode.quiet.rawValue
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func symbol(for mode: ReminderMode) -> String {
        switch mode {
        case .quiet: "bell.slash.fill"
        case .normal: "bell.fill"
        case .aggressive: "alarm.fill"
        }
    }

    private func tint(for mode: ReminderMode) -> Color {
        switch mode {
        case .quiet: .secondary
        case .normal: .fuelBlue
        case .aggressive: .liftEatsCoral
        }
    }
}
