//
//  TodayMediumView.swift
//  TodayWidget
//

import SwiftUI
import WidgetKit

/// The home-screen medium widget: the small widget's headline, plus the grams
/// eaten against each target — `design.md`, the Widgets row.
struct TodayMediumView: View {
    let snapshot: TodaySnapshot?

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        GeometryReader { proxy in
            let point = proxy.size.height / WidgetCanvas.height
            ZStack(alignment: .topLeading) {
                WidgetMascot(move: .today(snapshot), side: 168, origin: CGPoint(x: -12, y: -4))
                Group {
                    if let snapshot {
                        day(snapshot)
                    } else {
                        TodayEmptyNote(action: TodayCopy.emptyActionWide)
                            .frame(maxHeight: .infinity)
                    }
                }
                // The column starts where the mascot ends, so it scales with it.
                .padding(EdgeInsets(top: 15 * point, leading: 156 * point, bottom: 14 * point, trailing: 14))
            }
        }
    }

    private func day(_ snapshot: TodaySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            TodayHeadline(snapshot: snapshot, size: Circa.Display.widgetMediumTotal)
            Spacer(minLength: 0)
            macroRow(snapshot)
                // Three columns on the narrowest iPhones have no room to grow.
                .dynamicTypeSize(...DynamicTypeSize.large)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    /// Tinted and clear keep only opacity, so a solid card would bury everything on it.
    @ViewBuilder
    private func macroRow(_ snapshot: TodaySnapshot) -> some View {
        let row = HStack(alignment: .top, spacing: 12) {
            macro(.protein, "Protein", eaten: snapshot.eaten.protein, target: snapshot.target.protein)
            macro(.carbs, "Carbs", eaten: snapshot.eaten.carbs, target: snapshot.target.carbs)
            macro(.fat, "Fat", eaten: snapshot.eaten.fat, target: snapshot.target.fat)
        }
        if renderingMode == .fullColor {
            CircaCard(.raised, radius: Circa.Radius.cardSmall, inset: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)) {
                row
            }
        } else {
            row
        }
    }

    /// Grams eaten only: a widget column has no room for "81 / 165".
    private func macro(_ glyph: CircaMacroGlyph.Macro, _ name: String, eaten: Double, target: Double) -> some View {
        let value = CircaMacroValue(consumed: Int(eaten.rounded()), target: Int(target.rounded()))
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                CircaInlineGlyph(glyph)
                    .foregroundStyle(Color.circaInk2)
                Text("\(value.consumed)")
                    .font(.circaMono.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color.circaInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            CircaMacroBar(value: value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value.spoken(name))
    }
}
