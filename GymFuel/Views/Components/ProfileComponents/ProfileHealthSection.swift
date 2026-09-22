import SwiftUI

/// The durable home for the Apple Health connection.
///
/// Built in the legacy Profile idiom rather than Circa on purpose: this is a
/// `ProfileView` row, and that whole screen is rebuilt in one pass in Step 7.
/// A single Circa card sitting among eight material ones would read as a bug.
struct ProfileHealthSection: View {
    let userId: String
    let preferredColorScheme: ColorScheme?
    /// Reports a weight the import moved, so the caller can refresh the profile
    /// it owns — the same contract `StatsView.onWeighIn` uses.
    let onWeightImported: (Double) -> Void

    @EnvironmentObject private var healthWeightSync: HealthWeightSyncService
    @State private var showDetails = false

    var body: some View {
        // Nothing to offer on hardware with no Health database.
        if healthWeightSync.isAvailable {
            VStack(spacing: 12) {
                ProfileSectionHeader(title: "Apple Health", systemImage: "heart.text.square")

                Button {
                    if healthWeightSync.isConnected {
                        showDetails = true
                    } else {
                        Task { await connect() }
                    }
                } label: {
                    ProfileSettingsRow(
                        title: "Weight Sync",
                        systemImage: "scalemass.fill",
                        value: rowValue,
                        tint: .fuelBlue
                    )
                }
                .buttonStyle(.plain)
                .background(ProfileCardBackground())
                .disabled(healthWeightSync.isSyncing)
            }
            .padding(.horizontal)
            .sheet(isPresented: $showDetails) {
                detailSheet
                    .preferredColorScheme(preferredColorScheme)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(34)
            }
        }
    }

    private var rowValue: String {
        if healthWeightSync.isSyncing { return "Syncing…" }
        return healthWeightSync.isConnected ? "Connected" : "Not connected"
    }

    // MARK: - Detail sheet

    private var detailSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()

                Button {
                    showDetails = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(Color(.secondarySystemBackground), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(healthWeightSync.isSyncing)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(spacing: 7) {
                        Text("Weigh-ins arrive on their own")
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.center)

                        Text("If your scale writes to Apple Health, LiftEats picks those weights up and adds them to your trend.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16)

                    VStack(spacing: 10) {
                        detailRow(
                            symbol: "scalemass.fill",
                            title: "Body weight only",
                            detail: "Nothing else is read. No activity, no workouts, no steps."
                        )
                        detailRow(
                            symbol: "arrow.down.circle.fill",
                            title: "Read, never written",
                            detail: "LiftEats never writes anything back into Apple Health."
                        )
                        detailRow(
                            symbol: "hand.raised.fill",
                            title: "Your weigh-ins win",
                            detail: "A weight you enter yourself is never replaced by one from Health."
                        )
                    }

                    // No "denied" state is possible: iOS reports a refused read
                    // and an empty Health database identically. So point at the
                    // place the user can actually check, and claim nothing.
                    Text("Weights not showing up? Open the Health app → Sharing → Apps to see what LiftEats can read.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)

                    Button {
                        Task { await syncNow() }
                    } label: {
                        HStack(spacing: 8) {
                            if healthWeightSync.isSyncing {
                                ProgressView().controlSize(.small)
                            }
                            Text(healthWeightSync.isSyncing ? "Syncing…" : "Sync now")
                                .font(.headline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.liftEatsCoral, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(healthWeightSync.isSyncing)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemBackground))
    }

    private func detailRow(symbol: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.fuelBlue)
                .frame(width: 48, height: 48)
                .background(Color.fuelBlue.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Actions

    private func connect() async {
        if let kg = await healthWeightSync.connect(userId: userId) {
            onWeightImported(kg)
        }
    }

    private func syncNow() async {
        if let kg = await healthWeightSync.syncIfConnected(userId: userId) {
            onWeightImported(kg)
        }
    }
}
