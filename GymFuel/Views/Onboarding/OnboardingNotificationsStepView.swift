//
//  OnboardingNotificationsStepView.swift
//  GymFuel
//
//  Step 3a — the soft pre-prompt.
//
//  Only an explicit enable tap may request notification permission.
//

import SwiftUI

struct OnboardingNotificationsStepView: View {
    /// 1-based position in the flow, and the flow's length. Passed in rather
    /// than derived so the counter can never disagree with the progress bar
    /// sitting directly above it.
    let stepPosition: Int
    let stepCount: Int
    /// Called on both paths — Enable and Not now both continue to the summary.
    let onFinished: () -> Void

    @State private var isRequesting = false
    @Environment(\.dynamicTypeSize) private var typeSize

    /// design.md rule 8. At accessibility sizes the rows drop their wells and
    /// the text takes the full width instead of wrapping into a 38pt-indented
    /// column.
    private var isStacked: Bool { typeSize.isAccessibilitySize }

    private static let analyticsStep = "notifications"

    private let reasons: [ReminderReason] = [
        ReminderReason(
            symbol: "clock",
            title: "Three times a day",
            detail: "\(ReminderMode.normal.scheduleDescription)."
        ),
        ReminderReason(
            symbol: "text.bubble",
            title: "Keep it simple",
            detail: "A few words or a photo are enough."
        ),
        ReminderReason(
            symbol: "slider.horizontal.3",
            title: "You choose the pace",
            detail: "Choose more reminders or turn them off in Settings."
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
            CircaSectionLabel("Reminders · \(stepPosition) of \(stepCount)")

            Text("Want a reminder to write?")
                .font(.circaTitle)
                .foregroundStyle(Color.circaInk)
                .fixedSize(horizontal: false, vertical: true)

            Text("A little reminder to make room for your food diary.")
                .font(.circaBody)
                .foregroundStyle(Color.circaInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func row(_ reason: ReminderReason) -> some View {
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

    private func rowText(_ reason: ReminderReason) -> some View {
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
            Text("Turning this on asks iOS for permission.\nYou can change it in Settings whenever.")
                .font(.circaMono)
                .foregroundStyle(Color.circaInk3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task { await enable() }
            } label: {
                Group {
                    if isRequesting {
                        ProgressView()
                            .tint(Color.circaPaperTop)
                    } else {
                        Text("Turn reminders on")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.circa(.primary, height: 52))
            .disabled(isRequesting)

            Button("Not now") {
                Task { await skip() }
            }
            .buttonStyle(.circa(.quiet))
            .disabled(isRequesting)
        }
        .padding(.horizontal, Circa.Space.screenMargin)
        .padding(.bottom, 16)
    }

    // MARK: - Actions

    @MainActor
    private func enable() async {
        guard !isRequesting else { return }
        isRequesting = true

        do {
            // Onboarding can run before sign-up; RootView schedules once the account exists.
            try await ReminderService.shared.apply(.normal, mayAskPermission: true, scheduleNow: false)
            FirebaseTelemetryService.logOnboardingEvent("reminders_enabled", step: Self.analyticsStep)
        } catch {
            // The service falls back to Quiet; a denied prompt needs no second alert.
            FirebaseTelemetryService.logOnboardingEvent("reminders_denied", step: Self.analyticsStep)
        }

        isRequesting = false
        onFinished()
    }

    @MainActor
    private func skip() async {
        guard !isRequesting else { return }
        isRequesting = true
        try? await ReminderService.shared.apply(.quiet, mayAskPermission: false)
        isRequesting = false
        FirebaseTelemetryService.logOnboardingEvent("reminders_skipped", step: Self.analyticsStep)
        onFinished()
    }
}

private struct ReminderReason: Identifiable {
    let symbol: String
    let title: String
    let detail: String

    var id: String { title }
}

#Preview("Reminders · light") {
    OnboardingNotificationsStepView(stepPosition: 12, stepCount: 13, onFinished: {})
}

#Preview("Reminders · dark") {
    OnboardingNotificationsStepView(stepPosition: 12, stepCount: 13, onFinished: {})
        .preferredColorScheme(.dark)
}

#Preview("Reminders · AX3") {
    OnboardingNotificationsStepView(stepPosition: 12, stepCount: 13, onFinished: {})
        .dynamicTypeSize(.accessibility3)
}
