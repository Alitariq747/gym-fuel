//
//  OnboardingMetricControls.swift
//  GymFuel
//
//  The shape every metric step shares: one reading on the page, the wheel
//  behind a tap.
//
//  The wheel used to sit on the page under a summary card. Between the mascot,
//  the title, the unit control and a 160 pt wheel, the step overflowed a 14 Pro
//  Max — so putting a wheel back on a metric step reintroduces the scroll.
//

import SwiftUI

/// The one reading on a metric step, and the way into its wheel.
struct OnboardingValueCard: View {
    let value: String
    /// What the reading is, for VoiceOver — "Height", "Current weight".
    let label: String
    let action: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var readingSize: CGFloat = 52

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Circa.Radius.card, style: .continuous)
    }

    var body: some View {
        Button(action: action) {
            CircaCard(inset: EdgeInsets(top: 26, leading: 18, bottom: 26, trailing: 18)) {
                VStack(spacing: 8) {
                    Text(value)
                        .font(.system(size: readingSize, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.circaAccentLarge)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    HStack(spacing: 6) {
                        Text("Tap to change")
                        Image(systemName: "pencil")
                    }
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk3)
                }
                .frame(maxWidth: .infinity)
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
        .accessibilityHint("Opens the picker")
        .accessibilityAddTraits(.isButton)
    }
}

/// The sheet a value card opens: title, unit toggle, wheel, Done.
///
/// Done only dismisses. The wheel writes straight through to the step's state,
/// so swiping the sheet away keeps the same value Done would have kept.
struct OnboardingWheelSheet<Toggle: View, Wheel: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let height: CGFloat
    private let unitToggle: Toggle
    private let wheel: Wheel

    init(
        title: String,
        height: CGFloat = 360,
        @ViewBuilder unitToggle: () -> Toggle,
        @ViewBuilder wheel: () -> Wheel
    ) {
        self.title = title
        self.height = height
        self.unitToggle = unitToggle()
        self.wheel = wheel()
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Text(title)
                    .font(.circaTitle)
                    .foregroundStyle(Color.circaInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 0)

                unitToggle
            }

            wheel
                .frame(maxWidth: .infinity)

            Button { dismiss() } label: {
                Text("Done").frame(maxWidth: .infinity)
            }
            .buttonStyle(.circa(.primary, height: 52))
        }
        .padding(.horizontal, Circa.Space.screenMargin)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .circaPaper()
        .presentationDetents([.height(dynamicTypeSize.isAccessibilitySize ? height + 110 : height)])
        .presentationDragIndicator(.visible)
    }
}

#Preview("Value card") {
    VStack(spacing: 20) {
        OnboardingValueCard(value: "5′ 7″", label: "Height", action: {})
        OnboardingValueCard(value: "83.0 kg", label: "Current weight", action: {})
    }
    .padding(Circa.Space.screenMargin)
    .frame(maxHeight: .infinity)
    .circaPaper()
}

#Preview("Wheel sheet · dark") {
    OnboardingWheelSheet(title: "Your height") {
        UnitToggle(
            options: ["cm", "ft/in"],
            label: { $0 },
            selection: .constant("ft/in")
        )
    } wheel: {
        Picker("Centimetres", selection: .constant(175)) {
            ForEach(120...220, id: \.self) { Text("\($0) cm").tag($0) }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .frame(height: 170)
    }
    .preferredColorScheme(.dark)
}
