//
//  StatsWeekPicker.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 08/05/2025.
//

import SwiftUI

/// The Week screen's header, from the `Week` artboard: a stacked title and mono
/// range, and the two week steps.
struct StatsWeekPicker: View {
    let title: String
    let rangeLabel: String
    let isLoading: Bool
    let canGoNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            weekBlock
                .frame(minHeight: Circa.minHitTarget, alignment: .topLeading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(title), \(rangeLabel)")

            Spacer(minLength: 8)

            if isLoading {
                ProgressView()
                    .tint(Color.circaAccent)
                    .frame(height: Circa.minHitTarget)
            }

            weekStep("chevron.left", label: "Previous week", isEnabled: true, action: onPrevious)
            weekStep("chevron.right", label: "Next week", isEnabled: canGoNext, action: onNext)
        }
    }

    private var weekBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.circaTitle)
                .foregroundStyle(Color.circaInk)
            Text(rangeLabel.uppercased())
                .font(.circaMono)
                .tracking(Circa.sectionLabelTracking)
                .foregroundStyle(Color.circaInk3)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func weekStep(
        _ systemName: String,
        label: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(isEnabled ? Color.circaInk : Color.circaDotted)
                .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }
}

#Preview {
    VStack(spacing: 24) {
        StatsWeekPicker(
            title: "This week",
            rangeLabel: "Mon 8 – Sun 14 Sep",
            isLoading: false,
            canGoNext: false,
            onPrevious: {},
            onNext: {}
        )
        StatsWeekPicker(
            title: "Week of 25 Aug",
            rangeLabel: "Mon 25 Aug – Sun 31 Aug",
            isLoading: true,
            canGoNext: true,
            onPrevious: {},
            onNext: {}
        )
    }
    .padding(Circa.Space.screenMargin)
    .circaPaper()
}
