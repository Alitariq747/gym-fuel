import SwiftUI

/// The durable home for the Apple Health connection.
struct ProfileHealthSection: View {
    let userId: String
    /// Reports a weight the import moved, so the caller can refresh the profile
    /// it owns — the same contract `StatsView.onWeighIn` uses.
    let onWeightImported: (Double) -> Void

    @EnvironmentObject private var healthWeightSync: HealthWeightSyncService
    @State private var showSettingsHint = false

    var body: some View {
        // Nothing to offer on hardware with no Health database.
        if healthWeightSync.isAvailable {
            VStack(spacing: 12) {
                ProfileSectionHeader(title: "Apple Health")

                Button {
                    Task { await rowTapped() }
                } label: {
                    ProfileSettingsRow(
                        title: "Weight Sync",
                        systemImage: "scalemass.fill",
                        value: rowValue,
                        detail: rowDetail
                    )
                }
                .buttonStyle(.plain)
                .background(ProfileCardBackground())
                .disabled(healthWeightSync.isSyncing)
            }
            .padding(.horizontal, Circa.Space.screenMargin)
            .alert(settingsHint.title, isPresented: $showSettingsHint) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(settingsHint.message)
            }
        }
    }

    private var rowValue: String {
        HealthSyncCopy.status(
            isConnected: healthWeightSync.isConnected,
            isSyncing: healthWeightSync.isSyncing
        )
    }

    private var rowDetail: String? {
        HealthSyncCopy.detail(
            isSyncing: healthWeightSync.isSyncing,
            lastFoundDateKey: healthWeightSync.lastFoundDateKey
        )
    }

    private var settingsHint: (title: String, message: String) {
        HealthSyncCopy.settingsHint(isConnected: healthWeightSync.isConnected)
    }

    // MARK: - Actions

    /// Only a tap before iOS has ever asked raises its sheet; every other tap
    /// says where the switch lives.
    private func rowTapped() async {
        guard !healthWeightSync.isConnected, await healthWeightSync.willAskForAccess() else {
            showSettingsHint = true
            return
        }

        if let kg = await healthWeightSync.connect(userId: userId) {
            onWeightImported(kg)
        }
    }
}
