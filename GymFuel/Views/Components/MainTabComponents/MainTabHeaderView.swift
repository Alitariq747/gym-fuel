import SwiftUI

/// The Day screen's header, from the `Day` artboard: a stacked title and mono
/// date that together open the date picker, then Week and Settings.
///
/// There are no date chevrons. Days change by swiping the journal
/// (`MainTabView.handleDaySwipe`), so the date block only opens the picker.
struct MainTabHeaderView: View {
    let selectedDate: Date
    let navigationDirection: DayNavigationDirection
    let onDateTap: () -> Void
    let onWeekTap: () -> Void
    let onSettingsTap: () -> Void

    private var title: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) { return "Today" }
        if calendar.isDateInYesterday(selectedDate) { return "Yesterday" }
        return shortDate
    }

    private var shortDate: String {
        selectedDate.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    /// Directional, so a swiped day enters from the side it was swiped from.
    private var dateChangeTransition: AnyTransition {
        switch navigationDirection {
        case .previous:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        case .next:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onDateTap) {
                ZStack(alignment: .topLeading) {
                    dateBlock
                        .id(selectedDate)
                        .transition(dateChangeTransition)
                }
                .frame(minHeight: Circa.minHitTarget, alignment: .topLeading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title), \(shortDate)")
            .accessibilityHint("Choose a date")
            .animation(.easeInOut(duration: 0.24), value: selectedDate)

            Spacer(minLength: 8)

            HStack(spacing: 0) {
                headerButton("calendar", label: "Week", action: onWeekTap)
                headerButton("gearshape", label: "Settings", action: onSettingsTap)
            }
        }
    }

    private func headerButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(Color.circaInk)
                .frame(width: Circa.minHitTarget, height: Circa.minHitTarget, alignment: .trailing)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var dateBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.circaTitle)
                    .foregroundStyle(Color.circaInk)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.circaInk)
            }
            Text(shortDate.uppercased())
                .font(.circaMono)
                .tracking(Circa.sectionLabelTracking)
                .foregroundStyle(Color.circaInk3)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    VStack(spacing: 24) {
        MainTabHeaderView(
            selectedDate: .now,
            navigationDirection: .previous,
            onDateTap: {},
            onWeekTap: {},
            onSettingsTap: {}
        )
        MainTabHeaderView(
            selectedDate: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now,
            navigationDirection: .previous,
            onDateTap: {},
            onWeekTap: {},
            onSettingsTap: {}
        )
    }
    .padding(Circa.Space.screenMargin)
    .circaPaper()
}
