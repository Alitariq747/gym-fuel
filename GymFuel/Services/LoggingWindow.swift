import Foundation

/// Which days the journal may show, and which of those may be written to.
///
/// Two separate questions, and conflating them is the mistake this type exists
/// to prevent. **Older days can be read but not written to** — `design.md`,
/// *Navigation* — so a day outside the editable window is still a perfectly
/// valid day to select; it just loses the dock.
///
/// Pure: no Firebase, no UI.
struct LoggingWindow {
    /// How many days back from today may still be logged to. The window is this
    /// many days *plus* today.
    static let editableDays = 7

    var calendar: Calendar = .current

    /// Whether the day may be shown at all. The hard rule: a day that has not
    /// happened yet cannot be selected, because an entry logged on it would be
    /// stamped in the future and stay there.
    func canSelect(_ date: Date, now: Date = .now) -> Bool {
        calendar.startOfDay(for: date) <= calendar.startOfDay(for: now)
    }

    /// Whether the day may be written to. The soft rule: it drives what the
    /// screen offers, never what it will load.
    func canLog(on date: Date, now: Date = .now) -> Bool {
        let day = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: now)
        guard day <= today else { return false }
        guard let oldest = calendar.date(byAdding: .day, value: -Self.editableDays, to: today) else {
            return false
        }
        return day >= oldest
    }

    /// The nearest day that may be shown. Only the future end is clamped —
    /// clamping the past would stop older days being read.
    func clampToSelectable(_ date: Date, now: Date = .now) -> Date {
        canSelect(date, now: now) ? date : calendar.startOfDay(for: now)
    }
}
