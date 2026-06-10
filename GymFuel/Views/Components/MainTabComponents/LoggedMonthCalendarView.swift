import SwiftUI

struct LoggedMonthCalendarView: View {
    let visibleMonth: Date
    let selectedDate: Date
    let loggedDays: Set<Date>
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void
    let onSelectDate: (Date) -> Void
    let onSelectFutureDate: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    private var calendar: Calendar {
        .current
    }

    private var monthTitle: String {
        visibleMonth.formatted(.dateTime.month(.wide).year())
    }

    private var orderedWeekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let startIndex = calendar.firstWeekday - 1
        return Array(symbols[startIndex..<symbols.count]) + Array(symbols[0..<startIndex])
    }

    private var calendarDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: visibleMonth),
              let firstVisibleWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        return (0..<42).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: firstVisibleWeek.start)
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button(action: onPreviousMonth) {
                    Image(systemName: "chevron.left")
                        .frame(width: 34, height: 34)
                }

                Spacer()

                Text(monthTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Button(action: onNextMonth) {
                    Image(systemName: "chevron.right")
                        .frame(width: 34, height: 34)
                }
            }
            .buttonStyle(.plain)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(orderedWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(calendarDays, id: \.self) { date in
                    calendarDayCell(date)
                }
            }
        }
    }

    private func calendarDayCell(_ date: Date) -> some View {
        let day = calendar.startOfDay(for: date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let isFuture = day > calendar.startOfDay(for: .now)
        let isInVisibleMonth = calendar.isDate(date, equalTo: visibleMonth, toGranularity: .month)
        let hasLogs = loggedDays.contains(day)

        let backgroundColor: Color = if isSelected {
            Color.fuelBlue
        } else if hasLogs && isInVisibleMonth {
            Color.fuelBlue.opacity(0.12)
        } else {
            Color.clear
        }
        let textColor: Color = if isSelected {
            Color.white
        } else if isFuture {
            Color.secondary.opacity(0.55)
        } else if hasLogs && isInVisibleMonth {
            Color.fuelBlue
        } else {
            Color.primary
        }
        let borderColor: Color = isToday && !isSelected && !(hasLogs && isInVisibleMonth) ? Color.primary.opacity(0.55) : Color.clear

        return Button {
            isFuture ? onSelectFutureDate() : onSelectDate(date)
        } label: {
            Text("\(calendar.component(.day, from: date))")
                .font(.subheadline.weight(isSelected || isToday ? .semibold : .medium))
                .foregroundStyle(textColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(backgroundColor))
                .overlay(Circle().stroke(borderColor, lineWidth: 1))
                .frame(height: 44)
                .opacity(isInVisibleMonth ? 1 : 0.35)
        }
        .buttonStyle(.plain)
    }
}
#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)
    let loggedDays = Set([0, -1, -3, -6].compactMap {
        calendar.date(byAdding: .day, value: $0, to: today)
    })

    LoggedMonthCalendarView(
        visibleMonth: today,
        selectedDate: today,
        loggedDays: loggedDays,
        onPreviousMonth: {},
        onNextMonth: {},
        onSelectDate: { _ in },
        onSelectFutureDate: {}
    )
    .padding()
}

