//
//  DateStripView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/01/2026.
//

import SwiftUI

struct DateStripView: View {
    @Binding var selectedDate: Date

    let pastDays: Int
    let futureDays: Int

    init(
        selectedDate: Binding<Date>,
        pastDays: Int = 15,
        futureDays: Int = 15
    ) {
        self._selectedDate = selectedDate
        self.pastDays = pastDays
        self.futureDays = futureDays
    }

    // MARK: - Date range

    private var dateRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let start = calendar.date(byAdding: .day, value: -pastDays, to: today) else {
            return [today]
        }

        let totalDays = pastDays + futureDays
        return (0...totalDays).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(dateRange, id: \.self) { date in
                    Button {
                        selectedDate = date
                    } label: {
                        dateCell(for: date)
                    }
                    .id(date)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
        .onAppear {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            // Make sure today's date is in our range, then scroll to it
            if dateRange.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
                proxy.scrollTo(today, anchor: .center)
            }
        }
    }
    }

    // MARK: - Single date pill

    private func dateCell(for date: Date) -> some View {
        let calendar = Calendar.current
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)

        // Formatters – fine like this for now; if you want to optimise later, make them static.
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = .current
        weekdayFormatter.dateFormat = "EEE" // Mon, Tue…

        let dayFormatter = DateFormatter()
        dayFormatter.locale = .current
        dayFormatter.dateFormat = "d" // 1, 2, 3…

        let weekdayText = weekdayFormatter.string(from: date).uppercased()
        let dayNumberText = dayFormatter.string(from: date)

        // Colors
        let selectedBackground = Color(.systemBackground)
        let selectedForeground = Color(.systemGray)
        let todayForeground = Color(.systemGray)
        let normalForeground = Color(.secondaryLabel)

        return VStack(spacing: 4) {
            Text(weekdayText)
                .font(.caption2.weight(.semibold))
            Text(dayNumberText)
                .font(.body.weight(.semibold))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(minWidth: 44) // usable tap target
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected ? selectedBackground : Color.clear)
        )
        .foregroundStyle(
            isSelected
            ? selectedForeground
            : (isToday ? todayForeground : normalForeground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isToday && !isSelected ? todayForeground.opacity(0.5) : .clear,
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    ZStack {
        AppBackground()
        DateStripView(selectedDate: .constant(Date()), pastDays: 15, futureDays: 15)
    }
   
}
