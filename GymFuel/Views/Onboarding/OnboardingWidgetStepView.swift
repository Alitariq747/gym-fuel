//
//  OnboardingWidgetStepView.swift
//  GymFuel
//
//  How to add the Today widget. Nothing is asked of iOS, so Continue is the only
//  way on.
//

import SwiftUI

struct OnboardingWidgetStepView: View {
    /// 1-based position in the flow, and the flow's length. Passed in rather
    /// than derived so the counter can never disagree with the progress bar
    /// sitting directly above it.
    let stepPosition: Int
    let stepCount: Int
    let onFinished: () -> Void

    @State private var place: WidgetGuideCopy.Place = .homeScreen
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .caption2) private var numberWell: CGFloat = 32

    /// design.md rule 8, as on the reminders step: the number joins the line.
    private var isStacked: Bool { typeSize.isAccessibilitySize }

    private static let previewHeight: CGFloat = 198
    private static let widgetSize = CGSize(width: 338, height: 158)
    private static let widgetScale: CGFloat = 0.86

    /// The system's wallpaper, drawn for placement only: not a Circa colour.
    private static let lockWallpaper = LinearGradient(
        colors: [Color(red: 0x3B / 255, green: 0x37 / 255, blue: 0x32 / 255),
                 Color(red: 0x54 / 255, green: 0x4A / 255, blue: 0x3F / 255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private var steps: [String] {
        if #available(iOS 18, *) {
            WidgetGuideCopy.steps(for: place, hasEditButton: true)
        } else {
            WidgetGuideCopy.steps(for: place, hasEditButton: false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            AdaptiveScrollContainer {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    VStack(alignment: .leading, spacing: 14) {
                        preview
                        UnitToggle(options: WidgetGuideCopy.Place.allCases, label: \.title, selection: $place)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            row(number: index + 1, step)
                        }
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
            CircaSectionLabel("Widget · \(stepPosition) of \(stepCount)")

            Text("Keep today in view")
                .font(.circaTitle)
                .foregroundStyle(Color.circaInk)
                .fixedSize(horizontal: false, vertical: true)

            Text("Add the widget to see what's left of today without opening Circa.")
                .font(.circaBody)
                .foregroundStyle(Color.circaInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Both panels share one frame, so switching moves nothing below them. Not
    /// the person's numbers, so VoiceOver skips them.
    private var preview: some View {
        Group {
            switch place {
            case .homeScreen: homeScreenPreview
            case .lockScreen: lockScreenPreview
            }
        }
        .frame(maxWidth: .infinity, minHeight: Self.previewHeight, maxHeight: Self.previewHeight, alignment: .top)
        .background {
            switch place {
            case .homeScreen: Color.circaMediaWell
            case .lockScreen: Self.lockWallpaper
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Circa.Radius.card, style: .continuous))
        .dynamicTypeSize(.large)
        .accessibilityHidden(true)
    }

    /// The real widget on the gallery's made-up day, so it looks the same when
    /// the person searches for it.
    private var homeScreenPreview: some View {
        let size = Self.widgetSize
        let scale = Self.widgetScale

        return VStack(spacing: 5) {
            TodayMediumView(snapshot: .sample())
                .frame(width: size.width, height: size.height)
                .background(LinearGradient.circaPaper)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .scaleEffect(scale)
                .frame(width: size.width * scale, height: size.height * scale)

            Text("Circa")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.circaInk2)

            HStack(spacing: 28) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.circaInk.opacity(0.07))
                        .frame(width: 52, height: 52)
                }
            }
            .padding(.top, 8)
        }
        .padding(.top, 18)
    }

    /// The real Lock Screen widgets on the same day. Dark, so they draw white,
    /// as iOS draws them there.
    private var lockScreenPreview: some View {
        VStack(spacing: 2) {
            HStack(spacing: 8) {
                Text(.now, format: .dateTime.weekday(.abbreviated).day())
                Text(TodayCopy.inline(.sample()))
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)

            Text("9:41")
                .font(.system(size: 68, weight: .semibold))

            HStack(spacing: 14) {
                TodayRectangularView(snapshot: .sample())
                    .frame(width: 170, height: 72)
                TodayCircularView(snapshot: .sample())
                    .frame(width: 72, height: 72)
            }
        }
        .padding(.top, 12)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private func row(number: Int, _ step: String) -> some View {
        if isStacked {
            Text("\(number). \(instruction(step))")
                .font(.circaBody)
                .foregroundStyle(Color.circaInk2)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            HStack(alignment: .top, spacing: 14) {
                Text("\(number)")
                    .font(.circaMono.weight(.semibold))
                    .foregroundStyle(Color.circaInk2)
                    .frame(width: numberWell, height: numberWell)
                    .background(Color.circaWell, in: Circle())
                    .overlay { Circle().strokeBorder(Color.circaCardBorder, lineWidth: Circa.Rule.hairline) }
                    .accessibilityHidden(true)

                instruction(step)
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)

                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// What the person taps takes the primary ink.
    private func instruction(_ step: String) -> Text {
        var text = (try? AttributedString(markdown: step)) ?? AttributedString(step)
        for run in text.runs where run.inlinePresentationIntent == .stronglyEmphasized {
            text[run.range].foregroundColor = .circaInk
        }
        return Text(text)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Text("It fills in once you've finished setting up.")
                .font(.circaMono)
                .foregroundStyle(Color.circaInk3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                onFinished()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.circa(.primary, height: 52))
        }
        .padding(.horizontal, Circa.Space.screenMargin)
        .padding(.bottom, 16)
    }
}

#Preview("Widget · light") {
    OnboardingWidgetStepView(stepPosition: 13, stepCount: 14, onFinished: {})
}

#Preview("Widget · dark") {
    OnboardingWidgetStepView(stepPosition: 13, stepCount: 14, onFinished: {})
        .preferredColorScheme(.dark)
}
