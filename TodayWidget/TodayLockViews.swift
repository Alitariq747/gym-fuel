//
//  TodayLockViews.swift
//  TodayWidget
//
//  The Lock Screen: no mascot, and one system ring for calories only. iOS tints
//  everything here, so the views ask for primary and secondary, never a colour.
//

import SwiftUI
import WidgetKit

/// The circle: the ring, with what is left inside it.
struct TodayCircularView: View {
    let snapshot: TodaySnapshot?

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Gauge(value: snapshot?.calorieProgress ?? 0) {
                EmptyView()
            } currentValueLabel: {
                if let snapshot {
                    VStack(spacing: 2) {
                        Text(TodayCopy.number(snapshot))
                            .font(.circaMonoValue)
                            .minimumScaleFactor(0.6)
                        Text(TodayCopy.shortLabel(snapshot))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .lineLimit(1)
                } else {
                    calorieGlyph(side: 24)
                }
            }
            .gaugeStyle(.accessoryCircularCapacity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(snapshot.map(TodayCopy.spoken) ?? TodayCopy.inline(nil))
    }
}

/// The rectangle: the ring with the calorie glyph, then the number.
struct TodayRectangularView: View {
    let snapshot: TodaySnapshot?

    var body: some View {
        HStack(spacing: 8) {
            Gauge(value: snapshot?.calorieProgress ?? 0) {
                EmptyView()
            } currentValueLabel: {
                calorieGlyph(side: 24)
            }
            // The system ring keeps its own size; a smaller frame only makes it spill.
            .gaugeStyle(.accessoryCircularCapacity)

            VStack(alignment: .leading, spacing: 3) {
                if let snapshot {
                    Text(TodayCopy.number(snapshot))
                        .font(.system(size: Circa.Display.lockTotal, weight: .semibold, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(TodayCopy.label(snapshot))
                        .font(.circaCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(TodayCopy.emptyTitle)
                        .font(.circaRow.weight(.semibold))
                        .lineLimit(2)
                    Text(TodayCopy.emptyAction)
                        .font(.circaCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(snapshot.map(TodayCopy.spoken) ?? TodayCopy.inline(nil))
    }
}

/// The steaming bowl, as a template image so iOS can tint it. A function, not a
/// view type: as a gauge's whole value label, a separate view type did not draw.
private func calorieGlyph(side: CGFloat) -> some View {
    Image(CircaMacroGlyph.Macro.calories.rawValue)
        .resizable()
        .scaledToFit()
        .frame(width: side, height: side)
}
