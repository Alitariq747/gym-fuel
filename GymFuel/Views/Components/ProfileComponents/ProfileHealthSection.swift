import SwiftUI

/// The durable home for the Apple Health connection.
struct ProfileHealthSection: View {
    let userId: String
    let preferredColorScheme: ColorScheme?
    /// Reports a weight the import moved, so the caller can refresh the profile
    /// it owns — the same contract `StatsView.onWeighIn` uses.
    let onWeightImported: (Double) -> Void

    @EnvironmentObject private var healthWeightSync: HealthWeightSyncService
    @State private var showDetails = false
    @State private var showAsksOnce = false

    var body: some View {
        // Nothing to offer on hardware with no Health database.
        if healthWeightSync.isAvailable {
            VStack(spacing: 12) {
                ProfileSectionHeader(title: "Apple Health")

                Button {
                    if healthWeightSync.isConnected {
                        showDetails = true
                    } else {
                        Task { await turnOn() }
                    }
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
            .sheet(isPresented: $showDetails) {
                detailSheet
                    .preferredColorScheme(preferredColorScheme)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            // Switching on without a sheet appearing looks like the tap failed,
            // so it says why and where the switch the app cannot reach lives.
            .alert(HealthSyncCopy.asksOnceTitle, isPresented: $showAsksOnce) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(HealthSyncCopy.asksOnceBody)
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
            isConnected: healthWeightSync.isConnected,
            isSyncing: healthWeightSync.isSyncing,
            hasSynced: healthWeightSync.hasSynced,
            lastFoundDateKey: healthWeightSync.lastFoundDateKey
        )
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
                        .font(.circaRow)
                        .foregroundStyle(Color.circaInk2)
                        .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                        .background(Color.circaSunken, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(healthWeightSync.isSyncing)
            }
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.top, 12)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        CircaSectionLabel("Apple Health")
                        Text("Weigh-ins arrive on their own")
                            .font(.circaTitle)
                            .foregroundStyle(Color.circaInk)

                        Text("If your scale writes to Apple Health, Circa picks those weights up and adds them to your trend.")
                            .font(.circaBody)
                            .foregroundStyle(Color.circaInk2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 10) {
                        detailRow(
                            symbol: "scalemass.fill",
                            title: "Body weight only",
                            detail: "Nothing else is read. No activity, no workouts, no steps."
                        )
                        detailRow(
                            symbol: "arrow.down.circle.fill",
                            title: "Read, never written",
                            detail: "Circa never writes anything back into Apple Health."
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
                    Text("Weights not showing up? Open the Health app → Sharing → Apps to see what Circa can read.")
                        .font(.circaCaption)
                        .foregroundStyle(Color.circaInk2)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 10) {
                        Button {
                            Task { await syncNow() }
                        } label: {
                            Text(healthWeightSync.isSyncing ? HealthSyncCopy.syncing : "Sync now")
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.circa(.primary, height: 52))
                        .disabled(healthWeightSync.isSyncing)

                        // Stops future imports. Weigh-ins already imported stay:
                        // they are measurements, and Step 4e permits deleting
                        // typed ones only. It cannot revoke the iOS permission
                        // either — no API does — which is what the line above
                        // points at the Health app for.
                        Button {
                            healthWeightSync.disconnect()
                            showDetails = false
                        } label: {
                            Text("Disconnect")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.circa(.outline, height: 52))
                        .disabled(healthWeightSync.isSyncing)
                    }
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.bottom, 20)
            }
        }
        .circaPaper()
    }

    private func detailRow(symbol: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.circaRow)
                .foregroundStyle(Color.circaAccent)
                .frame(width: 44, height: 44)
                .background(Color.circaWell, in: RoundedRectangle(cornerRadius: Circa.Radius.thumb))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.circaRow)
                    .foregroundStyle(Color.circaInk)

                Text(detail)
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.circaCard, in: RoundedRectangle(cornerRadius: Circa.Radius.cardSmall, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Circa.Radius.cardSmall, style: .continuous)
                .strokeBorder(Color.circaCardBorder, lineWidth: 1)
        }
    }

    // MARK: - Actions

    /// Switches sync on, whether or not iOS will show its sheet.
    ///
    /// Read the state *before* connecting — connecting answers the prompt and
    /// would make every tap look like the first. When iOS has already been
    /// asked no sheet appears, so the row goes on silently and the alert
    /// explains it; switching on regardless is what makes a trip to the Health
    /// app worth taking, since a read enabled there needs this flag on to reach
    /// the trend.
    private func turnOn() async {
        let willAsk = await healthWeightSync.willAskForAccess()

        if let kg = await healthWeightSync.connect(userId: userId) {
            onWeightImported(kg)
        }

        if !willAsk { showAsksOnce = true }
    }

    private func syncNow() async {
        if let kg = await healthWeightSync.syncIfConnected(userId: userId) {
            onWeightImported(kg)
        }
    }
}
