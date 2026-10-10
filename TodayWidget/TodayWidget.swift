//
//  TodayWidget.swift
//  TodayWidget
//
//  Created by Ahmad Ali Tariq on 03/10/2026.
//

import WidgetKit
import SwiftUI

struct TodayEntry: TimelineEntry {
    let date: Date
    /// Already rolled over to `date`. `nil` when there is no note: never opened,
    /// signed out, or no saved target yet.
    let snapshot: TodaySnapshot?
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: .now, snapshot: .sample())
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        let now = Date.now
        let saved = TodaySnapshotStore.load()?.rolledOver(to: now)
        completion(TodayEntry(date: now, snapshot: saved ?? (context.isPreview ? .sample() : nil)))
    }

    /// Now, and the next midnight, so the day rolls over without the app.
    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let now = Date.now
        let saved = TodaySnapshotStore.load()
        let entries = [now, TodaySnapshot.nextMidnight(after: now)].map {
            TodayEntry(date: $0, snapshot: saved?.rolledOver(to: $0))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct TodayWidgetView: View {
    let entry: TodayEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Text(TodayCopy.inline(entry.snapshot))
        case .accessoryCircular:
            TodayCircularView(snapshot: entry.snapshot)
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
        case .accessoryRectangular:
            TodayRectangularView(snapshot: entry.snapshot)
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
        case .systemMedium:
            TodayMediumView(snapshot: entry.snapshot)
                // One step past standard: the mascot is beside the text, not under it.
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
        default:
            TodaySmallView(snapshot: entry.snapshot)
                // Standard size only: the last line sits just above the mascot's head.
                .dynamicTypeSize(...DynamicTypeSize.large)
        }
    }
}

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        // Renaming the kind removes the widget from every screen it is placed on.
        StaticConfiguration(kind: "TodayWidget", provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(for: .widget) { LinearGradient.circaPaper }
        }
        .configurationDisplayName("Today")
        .description("What's left of today's calories.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
        // The mascot is cropped by the widget's own edge; the text pads itself.
        .contentMarginsDisabled()
    }
}
