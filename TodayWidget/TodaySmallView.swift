//
//  TodaySmallView.swift
//  TodayWidget
//

import SwiftUI
import WidgetKit

/// The home-screen small widget — `design.md`, the Widgets row.
struct TodaySmallView: View {
    let snapshot: TodaySnapshot?

    var body: some View {
        let move = PlateMascot.Move.today(snapshot)
        ZStack(alignment: .topLeading) {
            // The wave sits further in so its raised arm stays on the widget. 4 pt
            // lower than the canvas, so a descender in the last line clears the plate.
            WidgetMascot(move: move, side: 126, origin: CGPoint(x: move == .wave ? 37 : 52, y: 78.5))
            Group {
                if let snapshot {
                    TodayHeadline(snapshot: snapshot, size: Circa.Display.widgetTotal)
                } else {
                    TodayEmptyNote(action: TodayCopy.emptyAction)
                }
            }
            .padding(EdgeInsets(top: 15, leading: 16, bottom: 0, trailing: 12))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
//
//#Preview("Small", as: .systemSmall) {
//    TodayWidget()
//} timeline: {
//    TodayEntry(date: .now, snapshot: .sample())
//    TodayEntry(date: .now, snapshot: .sample(eaten: 0, logged: 0))
//    TodayEntry(date: .now, snapshot: .sample(eaten: 2520))
//    TodayEntry(date: .now, snapshot: nil)
//}
