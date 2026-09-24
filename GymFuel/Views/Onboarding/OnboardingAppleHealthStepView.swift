//
//  OnboardingAppleHealthStepView.swift
//  GymFuel
//
//  The soft pre-prompt for Apple Health, built to the same two rules as
//  `OnboardingNotificationsStepView` — and one of its own.
//
//  1. **Nothing fires on appearance.** iOS raises its sheet once per data type,
//     ever. Only "Connect Apple Health" reaches HealthKit; the copy has to earn
//     the tap before the single system sheet is spent. "Not now" leaves it
//     unspent, so the Settings row can still raise it later.
//  2. **The three rows describe what this build actually reads** — body mass,
//     and nothing else, in one direction.
//  3. **There is no denied branch, and there cannot be one.**
//     `requestAuthorization` does not report a refusal: a user who taps Don't
//     Allow returns here exactly as one who allowed. So both buttons lead to the
//     same place and nothing on screen characterises the answer. Treating a
//     throw as a denial — as the notifications step legitimately does — would
//     reintroduce the bug that made Settings claim "Connected".
//

import SwiftUI

struct OnboardingAppleHealthStepView: View {
    /// 1-based position in the flow, and the flow's length. Passed in rather
    /// than derived so the counter can never disagree with the progress bar
    /// sitting directly above it.
    let stepPosition: Int
    let stepCount: Int
    /// Called on both paths — Connect and Not now both continue.
    let onFinished: () -> Void

    @EnvironmentObject private var healthWeightSync: HealthWeightSyncService

    @State private var isRequesting = false
    @Environment(\.dynamicTypeSize) private var typeSize

    /// design.md rule 8. At accessibility sizes the rows drop their wells and
    /// the text takes the full width instead of wrapping into a 38pt-indented
    /// column.
    private var isStacked: Bool { typeSize.isAccessibilitySize }

    private static let analyticsStep = "apple_health"

    /// The same three promises the Settings detail sheet makes. Said here first,
    /// because here is where they are load-bearing.
    private let reasons: [HealthReason] = [
        HealthReason(
            symbol: "scalemass",
            title: "Body weight only",
            detail: "Nothing else is read. No activity, no workouts, no steps."
        ),
        HealthReason(
            symbol: "arrow.down.circle",
            title: "Read, never written",
            detail: "Circa never writes anything back into Apple Health."
        ),
        HealthReason(
            symbol: "hand.raised",
            title: "Your weigh-ins win",
            detail: "A weight you enter yourself is never replaced by one from Health."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            AdaptiveScrollContainer {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    VStack(alignment: .leading, spacing: 13) {
                        ForEach(reasons) { row($0) }
                    }
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.top, 18)
                .padding(.bottom, 12)
            }

            footer
        }
        .circaPaper()
    }

    // MARK: - Parts

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            CircaSectionLabel("Apple Health · \(stepPosition) of \(stepCount)")

            Text("Let your weigh-ins arrive on their own?")
                .font(.circaTitle)
                .foregroundStyle(Color.circaInk)
                .fixedSize(horizontal: false, vertical: true)

            Text("If your scale writes to Apple Health, Circa picks those weights up and adds them to your trend. You never type them twice.")
                .font(.circaBody)
                .foregroundStyle(Color.circaInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func row(_ reason: HealthReason) -> some View {
        if isStacked {
            rowText(reason)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
        } else {
            HStack(alignment: .top, spacing: 14) {
                well(reason.symbol)
                rowText(reason)
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func rowText(_ reason: HealthReason) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(reason.title)
                .font(.circaEntryTitle)
                .foregroundStyle(Color.circaInk)

            Text(reason.detail)
                .font(.circaCaption)
                .foregroundStyle(Color.circaInk2)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 2)
    }

    private func well(_ symbolName: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: Circa.Radius.thumb, style: .continuous)

        return shape
            .fill(Color.circaWell)
            .frame(width: 38, height: 38)
            .overlay {
                Image(systemName: symbolName)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.circaInk2)
            }
            .overlay {
                shape.strokeBorder(Color.circaCardBorder, lineWidth: Circa.Rule.hairline)
            }
            .accessibilityHidden(true)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Text("Turning this on asks iOS for permission.\nYou can change it in the Health app whenever.")
                .font(.circaMono)
                .foregroundStyle(Color.circaInk3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task { await connect() }
            } label: {
                Group {
                    if isRequesting {
                        ProgressView()
                            .tint(Color.circaPaperTop)
                    } else {
                        Text("Connect Apple Health")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.circa(.primary, height: 52))
            .disabled(isRequesting)

            Button("Not now") {
                skip()
            }
            .buttonStyle(.circa(.quiet))
            .disabled(isRequesting)
        }
        .padding(.horizontal, Circa.Space.screenMargin)
        .padding(.bottom, 16)
    }

    // MARK: - Actions

    /// The only path that spends the install's single Health sheet.
    ///
    /// No success or failure branch, by rule 3 in the file note: allowed and
    /// refused are indistinguishable here. The import itself waits for a uid —
    /// sign-up comes after onboarding — and `RootView.importHealthWeight` runs
    /// it as soon as one exists.
    @MainActor
    private func connect() async {
        guard !isRequesting else { return }
        isRequesting = true

        await healthWeightSync.requestAccess()
        FirebaseTelemetryService.logOnboardingEvent("health_connected", step: Self.analyticsStep)

        isRequesting = false
        onFinished()
    }

    /// Touches nothing in HealthKit, leaving the one system ask unspent for the
    /// Settings row.
    private func skip() {
        FirebaseTelemetryService.logOnboardingEvent("health_skipped", step: Self.analyticsStep)
        onFinished()
    }
}

private struct HealthReason: Identifiable {
    let symbol: String
    let title: String
    let detail: String

    var id: String { title }
}

#Preview("Apple Health · light") {
    OnboardingAppleHealthStepView(stepPosition: 11, stepCount: 13, onFinished: {})
        .environmentObject(HealthWeightSyncService())
}

#Preview("Apple Health · dark") {
    OnboardingAppleHealthStepView(stepPosition: 11, stepCount: 13, onFinished: {})
        .environmentObject(HealthWeightSyncService())
        .preferredColorScheme(.dark)
}

#Preview("Apple Health · AX3") {
    OnboardingAppleHealthStepView(stepPosition: 11, stepCount: 13, onFinished: {})
        .environmentObject(HealthWeightSyncService())
        .dynamicTypeSize(.accessibility3)
}
