//
//  OnboardingNotificationsStepView.swift
//  GymFuel
//
//  Step 3a — the soft pre-prompt.
//
//  Two rules shape this screen, and both are easy to undo by accident:
//
//  1. **Nothing fires on appearance.** iOS grants exactly one
//     `requestAuthorization` per install and a denial is permanent from inside
//     the app — `ReminderService.hasAuthorization()` returns `false` forever
//     after, and Settings can then only point at iOS. So only "Turn reminders
//     on" reaches `ReminderService`; the copy has to earn the tap before the
//     single system alert is spent.
//  2. **The three rows describe what this build actually schedules** — three
//     fixed reminders a day. Suppression ("silence when you've logged") and the
//     weekly check-in nudge are Step 12 and Step 4. The canvas draws them; they
//     must not be promised here until they exist.
//
//  Built entirely from the Step 2a kit. Nothing from the old palette.
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

    @AppStorage(ReminderMode.preferenceKey)
    private var reminderModeValue = ReminderMode.quiet.rawValue

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
            detail: "9:00, 2:00 and 8:30. That's the whole schedule."
        ),
        ReminderReason(
            symbol: "text.bubble",
            title: "One line, then it's gone",
            detail: "A nudge to log what you ate. No badges, no streak alarms."
        ),
        ReminderReason(
            symbol: "slider.horizontal.3",
            title: "More, fewer, or none",
            detail: "Three paces to pick from, all in Settings."
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

            Text("The hardest part of any food journal is remembering to write in it. Three a day, and nothing else.")
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
                skip()
            }
            .buttonStyle(.circa(.quiet))
            .disabled(isRequesting)
        }
        .padding(.horizontal, Circa.Space.screenMargin)
        .padding(.bottom, 16)
    }

    // MARK: - Actions

    /// The only path that spends the install's single `requestAuthorization`.
    @MainActor
    private func enable() async {
        guard !isRequesting else { return }
        isRequesting = true

        do {
            try await ReminderService.shared.apply(.normal)
            reminderModeValue = ReminderMode.normal.rawValue
            FirebaseTelemetryService.logOnboardingEvent("reminders_enabled", step: Self.analyticsStep)
        } catch {
            // A denial is the user's answer, not an error to surface — an app
            // alert about the prompt they just dismissed is noise. The stored
            // mode follows what is actually scheduled, which is nothing.
            reminderModeValue = ReminderMode.quiet.rawValue
            FirebaseTelemetryService.logOnboardingEvent("reminders_denied", step: Self.analyticsStep)
        }

        isRequesting = false
        onFinished()
    }

    /// Writes `.quiet` explicitly rather than leaning on the stored default, so
    /// the saved mode always matches what is scheduled. Touches nothing in
    /// `ReminderService`, leaving the one system ask unspent for Settings.
    private func skip() {
        reminderModeValue = ReminderMode.quiet.rawValue
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
