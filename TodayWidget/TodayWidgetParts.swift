//
//  TodayWidgetParts.swift
//  TodayWidget
//
//  What the small and medium widgets both draw.
//

import SwiftUI
import WidgetKit

/// Every home-screen size is 158 pt tall on the canvas, so canvas points scale
/// by the real widget's height.
enum WidgetCanvas {
    static let height: CGFloat = 158
}

/// The number, its dotted rule, "kcal left" and the of-target line.
struct TodayHeadline: View {
    let snapshot: TodaySnapshot
    /// A `Circa.Display` size, scaled here with Dynamic Type.
    let size: CGFloat

    @ScaledMetric(relativeTo: .largeTitle) private var scale: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            CircaEstimate(
                TodayCopy.number(snapshot),
                certainty: snapshot.hasEstimate ? .estimated : .known,
                font: .system(size: size * scale, weight: .semibold, design: .monospaced)
            )
            .foregroundStyle(Color.circaAccentLarge)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .widgetAccentable()

            Text(TodayCopy.label(snapshot))
                .font(.circaCaption.weight(.medium))
                .foregroundStyle(Color.circaInk2)
            Text(TodayCopy.progress(snapshot))
                .font(.circaMono)
                .foregroundStyle(Color.circaInk3)
                .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(TodayCopy.spoken(snapshot))
    }
}

/// No note yet: never opened, signed out, or no saved target.
struct TodayEmptyNote: View {
    let action: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(TodayCopy.emptyTitle)
                .font(.circaRow.weight(.semibold))
                .foregroundStyle(Color.circaInk)
            Text(action)
                .font(.circaCaption)
                .foregroundStyle(Color.circaInk2)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The still mascot at a canvas position, cropped by the widget's edge.
struct WidgetMascot: View {
    let move: PlateMascot.Move
    let side: CGFloat
    let origin: CGPoint

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        // Tinted, clear and StandBy-at-night recolour everything, and the
        // mascot's drawings carry their own colours (mascot rule 7).
        if renderingMode == .fullColor {
            GeometryReader { proxy in
                let point = proxy.size.height / WidgetCanvas.height
                PlateMascot(move: move, isStill: true)
                    .frame(width: side * point, height: side * point)
                    .offset(x: origin.x * point, y: origin.y * point)
            }
        }
    }
}
