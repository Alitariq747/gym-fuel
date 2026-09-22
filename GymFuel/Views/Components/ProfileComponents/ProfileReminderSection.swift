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
            ProfileSectionHeader(title: "Reminders")

            Button {
                showPreferences = true
            } label: {
                ProfileSettingsRow(
                    title: "Logging Reminders",
                    systemImage: "bell.badge.fill",
                    value: selectedMode.displayName
                )
            }
            .buttonStyle(.plain)
            .background(ProfileCardBackground())
        }
        .padding(.horizontal, Circa.Space.screenMargin)
        .sheet(isPresented: $showPreferences) {
            preferenceSheet
                .preferredColorScheme(preferredColorScheme)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert("Reminders unavailable", isPresented: $showError) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Circa could not update your reminder preference.")
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
                        .font(.circaRow)
                        .foregroundStyle(Color.circaInk2)
                        .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                        .background(Color.circaSunken, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(isUpdatingMode)
            }
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        CircaSectionLabel("Reminders")
                        Text("A gentle nudge to log")
                            .font(.circaTitle)
                            .foregroundStyle(Color.circaInk)

                        Text("Choose how often Circa reminds you to log meals.")
                            .font(.circaBody)
                            .foregroundStyle(Color.circaInk2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 10) {
                        ForEach(ReminderMode.allCases) { mode in
                            modeButton(mode)
                        }
                    }
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.bottom, 20)
            }
        }
        .circaPaper()
    }

    private func modeButton(_ mode: ReminderMode) -> some View {
        let isSelected = selectedMode == mode
        return Button {
            Task { await select(mode) }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol(for: mode))
                    .font(.circaRow)
                    .foregroundStyle(Color.circaAccent)
                    .frame(width: 44, height: 44)
                    .background(Color.circaWell, in: RoundedRectangle(cornerRadius: Circa.Radius.thumb))

                VStack(alignment: .leading, spacing: 3) {
                    Text(mode.displayName)
                        .font(.circaRow)
                        .foregroundStyle(Color.circaInk)

                    Text(mode.scheduleDescription)
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if modeBeingApplied == mode {
                    ProgressView()
                        .controlSize(.small)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.circaAccent)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.circaCard, in: RoundedRectangle(cornerRadius: Circa.Radius.cardSmall, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Circa.Radius.cardSmall, style: .continuous)
                    .strokeBorder(isSelected ? Color.circaAccent : Color.circaCardBorder, lineWidth: 1)
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

}
