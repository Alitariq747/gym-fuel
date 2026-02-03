//
//  WeekPickerView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 19/01/2026.
//

import SwiftUI
import Foundation

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components)!
    }
    func daysInWeek(startingAt weekStart: Date) -> [Date] {
     
        let normalizedStart = startOfDay(for: startOfWeek(for: weekStart))

       
        return (0..<7).compactMap { dayOffset in
            date(byAdding: .day, value: dayOffset, to: normalizedStart)
        }
    }
}



struct WeekPickerView: View {
    @Binding var selectedWeekStart: Date

    private let calendar = Calendar.current


    private var weekStart: Date {
        calendar.startOfWeek(for: selectedWeekStart)
    }

    private var weekEnd: Date {
        calendar.date(byAdding: .day, value: 6, to: weekStart)!
    }

    private var currentWeekStart: Date {
        let today = Date()
        return calendar.startOfWeek(for: today)
    }

    private var canGoToNextWeek: Bool {
        weekStart < currentWeekStart
    }


    private var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let startText = formatter.string(from: weekStart)
        let endText = formatter.string(from: weekEnd)
        return "\(startText) – \(endText)"
    }

    var body: some View {
        HStack(spacing: 16) {

            // LEFT BUTTON: previous week
            Button {
                moveToPreviousWeek()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 10)
                    .background(Color(.systemBackground), in: Circle())
            }
            .buttonStyle(.plain)
         
            Text(weekRangeText)
                .font(.headline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)


      
            Button {
                moveToNextWeek()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 10)
                    .background(Color(.systemBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canGoToNextWeek)
            .opacity(canGoToNextWeek ? 1.0 : 0.3)
        }
        .padding(.horizontal)
    }


    private func moveToPreviousWeek() {
      
        if let newDate = calendar.date(byAdding: .day, value: -7, to: weekStart) {
            selectedWeekStart = newDate
        }
    }

    private func moveToNextWeek() {
        guard canGoToNextWeek else { return }

        if let newDate = calendar.date(byAdding: .day, value: 7, to: weekStart) {
            selectedWeekStart = newDate
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        WeekPickerView(selectedWeekStart: .constant(Date()))
    }
}
