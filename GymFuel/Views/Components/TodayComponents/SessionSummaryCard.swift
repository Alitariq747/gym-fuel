//
//  SessionSummaryCard.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 06/01/2026.
//

import SwiftUI

struct SessionSummaryCard: View {
    let dayLog: DayLog

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // if rest day
            if dayLog.isTrainingDay {
                HStack(alignment: .top, spacing: 16) {
                    Text("🏋️")
                         .font(.headline)
                         .padding(10)
                         .background(Color(.systemGray5), in: Circle())

                     VStack(alignment: .leading, spacing: 8) {
                         VStack(alignment: .leading, spacing: 0) {
                             Text("TODAY'S SESSION")
                                 .font(.caption2.weight(.medium))
                                 .foregroundStyle(.secondary)
                             Text("\(dayLog.trainingIntensity?.displayName ?? "Normal") day - \(dayLog.sessionType?.displayName ?? "Hypertrophy")")
                                 .font(.headline.bold())
                         }

                         HStack(spacing: 8) {
                             Image(systemName: "clock.fill")
                                 .font(.callout)
                                 .foregroundStyle(.secondary)

                             if let timeText = timeLabel {
                                 Text(timeText)
                                     .font(.subheadline.weight(.semibold))
                                     .foregroundStyle(.secondary)
                             }

                             Spacer()

                             HStack(spacing: 4) {
                                 Text("Intensity: ")
                                     .font(.system(size: 12, weight: .medium))
                                     .foregroundStyle(.primary)
                                 intensityBars
                             }
                             .padding(.horizontal, 8)
                             .padding(.vertical, 6)

                         }
                     }
                 }
                
            } else {
                HStack(alignment: .center, spacing: 20) {
                    Text("😴")
                        .font(.system(size: 28, weight: .regular))
                        .padding(8)
                        .background(Color(.systemGray5), in: Circle())
                    
                    VStack(alignment: .leading) {
                        Text("Rest Day - Recovery")
                            .font(.headline.bold())
                        Text("Prioritize sleep and rest today.")
                            .font(.callout.weight(.regular))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
            }
           
          


        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.9))
        )
        .shadow(
            color: Color.black.opacity(0.12),
            radius: 8,
            x: 0, y: 4
        )
    }

    private var intensityColor: Color {
        let intensity = dayLog.trainingIntensity ?? .normal

        switch intensity {
        case .recovery:
            return Color(.systemGray2)
        case .normal:
            return Color.blue
        case .hard:
            return Color.green
        case .allOut:
            return Color.red
        }
    }

    private var intensityBars: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .frame(width: 4, height: 14)
            }
        }
        .foregroundStyle(intensityColor)
    }


    private var timeLabel: String? {
        guard let start = dayLog.sessionStart else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: start)
    }
}


#Preview {
    ZStack {
        AppBackground()
        SessionSummaryCard(dayLog: DayLog.demoTrainingDay)
    }
}
