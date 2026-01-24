//
//  WeeklyFuelScoreChart.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 24/01/2026.
//

import SwiftUI
import Charts

struct WeeklyFuelScoreChart: View {
    
    let points: [DailyFuelScorePoint]
    
    var body: some View {
        Chart(points) { point in
            BarMark(
                x: .value("Day", point.date, unit: .day),
                y: .value("Score", point.score ?? 0)
            )
            .foregroundStyle(point.score ?? 0 >= 70 ? .fuelGreen.opacity(0.8) : .fuelRed.opacity(0.8))
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisTick()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                
            }
        }
        .frame(height: 220)
    }
}

#Preview {
    // Fake demo preview
    let cal = Calendar.current
    let start = cal.dateInterval(of: .weekOfYear, for: Date())!.start
    let demo = (0..<7).map { i in
        DailyFuelScorePoint(
            date: cal.date(byAdding: .day, value: i, to: start)!,
            score: [82, 65, 90, 10, 74, 88, 60][i]
        )
    }
    
    return WeeklyFuelScoreChart(points: demo)
        .padding()
    
}
